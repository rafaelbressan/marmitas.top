class SellerProfile < ApplicationRecord
  # Broadcast duration constants (configurable business logic)
  DEFAULT_BROADCAST_DURATION = 12.hours
  MAX_BROADCAST_DURATION = 96.hours

  # Associations
  belongs_to :user
  has_many :dishes, dependent: :destroy
  has_many :weekly_menus, dependent: :destroy
  has_many :selling_locations, dependent: :destroy
  belongs_to :current_location, class_name: 'SellingLocation', optional: true
  has_many :favorites, as: :favoritable, dependent: :destroy
  has_many :followers, through: :favorites, source: :user
  has_many :reviews, dependent: :destroy
  # TODO: Uncomment when model is created
  # has_many :activity_logs, dependent: :destroy

  # Active Storage
  has_one_attached :profile_photo
  has_many_attached :gallery_photos

  # Validations
  validates :business_name, presence: true
  validates :user_id, uniqueness: true
  validate :leaving_at_within_max_duration, if: -> { leaving_at.present? && arrived_at.present? }

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(currently_active: true) }
  scope :in_city, ->(city) { where(city: city) }

  # Find active sellers nearby using PostGIS geography calculations
  # Returns sellers within radius_km of the given latitude/longitude
  # Only includes sellers who are currently active and broadcasting their location
  def self.nearby(lat, lng, radius_km = 5)
    joins(:current_location)
      .where(currently_active: true)
      .where(
        sanitize_sql_array([
          "ST_DWithin(
            selling_locations.lonlat,
            ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
            ?
          )",
          lng, lat, radius_km * 1000
        ])
      )
      .select(
        "seller_profiles.*",
        sanitize_sql_array([
          "(ST_Distance(
            selling_locations.lonlat,
            ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
          ) / 1000.0) AS distance_km",
          lng, lat
        ])
      )
      .order('distance_km ASC')
  end

  # Callbacks
  after_commit :update_stats, on: [:create, :update]

  # Methods
  def current_menu
    weekly_menus.available_now.first
  end

  # Announce arrival at a location
  def announce_arrival(location_id, leaving_at: nil)
    location = selling_locations.find(location_id)

    # Default to DEFAULT_BROADCAST_DURATION (12 hours) if no leaving_at specified
    computed_leaving_at = leaving_at || (Time.current + DEFAULT_BROADCAST_DURATION)

    transaction do
      update!(
        current_location_id: location_id,
        currently_active: true,
        last_active_at: Time.current,
        arrived_at: Time.current,
        leaving_at: computed_leaving_at
      )
      # TODO: activity_logs.create!(activity_type: 'arrived', selling_location_id: location_id, occurred_at: Time.current)
    end

    # Send push notifications to followers (async to avoid slowing down the response)
    NotifyFollowersJob.perform_later(id, 'arrival') rescue nil

    self
  end

  # Announce departure
  def announce_departure
    transaction do
      update!(
        current_location_id: nil,
        currently_active: false,
        arrived_at: nil,
        leaving_at: nil
      )
      # TODO: activity_logs.create!(activity_type: 'departed', occurred_at: Time.current)
      # TODO: notify_followers(:departure)
    end

    self
  end

  # Check if broadcast has expired
  def broadcast_expired?
    return false unless leaving_at.present?
    Time.current >= leaving_at
  end

  # Auto-shutoff if past leaving time
  def auto_shutoff_if_expired!
    if broadcast_expired?
      announce_departure
      true
    else
      false
    end
  end

  # Rating and review methods

  # Calculate weighted average rating
  # Recent reviews (last 30 days) weighted 60%
  # Medium reviews (30-90 days) weighted 30%
  # Old reviews (90+ days) weighted 10%
  def recalculate_ratings!
    published_reviews = reviews.published

    # Get reviews grouped by age
    recent_reviews = published_reviews.recent.to_a
    medium_reviews = published_reviews.medium.to_a
    old_reviews = published_reviews.old.to_a

    return set_no_rating if published_reviews.count < 5

    # Calculate weighted average
    recent_sum = recent_reviews.sum(&:rating).to_f
    recent_count = recent_reviews.count
    medium_sum = medium_reviews.sum(&:rating).to_f
    medium_count = medium_reviews.count
    old_sum = old_reviews.sum(&:rating).to_f
    old_count = old_reviews.count

    recent_avg = recent_count > 0 ? recent_sum / recent_count : 0
    medium_avg = medium_count > 0 ? medium_sum / medium_count : 0
    old_avg = old_count > 0 ? old_sum / old_count : 0

    # Weighted calculation
    weighted_sum = (recent_avg * recent_count * 0.6) +
                   (medium_avg * medium_count * 0.3) +
                   (old_avg * old_count * 0.1)

    weighted_total = (recent_count * 0.6) + (medium_count * 0.3) + (old_count * 0.1)

    new_average = weighted_total > 0 ? (weighted_sum / weighted_total).round(2) : 0.0

    # Update rating distribution
    distribution = published_reviews.group(:rating).count

    update_columns(
      average_rating: new_average,
      reviews_count: published_reviews.count,
      rating_1_count: distribution[1] || 0,
      rating_2_count: distribution[2] || 0,
      rating_3_count: distribution[3] || 0,
      rating_4_count: distribution[4] || 0,
      rating_5_count: distribution[5] || 0
    )
  end

  # Get rating distribution as hash
  def rating_distribution
    {
      1 => rating_1_count,
      2 => rating_2_count,
      3 => rating_3_count,
      4 => rating_4_count,
      5 => rating_5_count
    }
  end

  # Check if rating should be displayed (minimum 5 reviews)
  def display_rating?
    reviews_count >= 5
  end

  # Get formatted rating display
  def rating_display
    if display_rating?
      "⭐ #{average_rating} (#{reviews_count} avaliações)"
    else
      "Novo vendedor (#{reviews_count} #{'avaliação'.pluralize(reviews_count)})"
    end
  end

  # Calculate rating trend (positive, negative, or stable)
  def rating_trend
    return :stable if reviews_count < 10

    recent = reviews.published.recent.average(:rating).to_f
    old = reviews.published.where('created_at < ?', 30.days.ago).average(:rating).to_f

    return :stable if recent == 0 || old == 0

    difference = recent - old

    if difference >= 0.3
      :improving
    elsif difference <= -0.3
      :declining
    else
      :stable
    end
  end

  private

  def set_no_rating
    update_columns(
      average_rating: 0.0,
      rating_1_count: 0,
      rating_2_count: 0,
      rating_3_count: 0,
      rating_4_count: 0,
      rating_5_count: 0
    )
  end

  def leaving_at_within_max_duration
    if leaving_at <= arrived_at
      errors.add(:leaving_at, "must be after arrival time")
    elsif leaving_at > arrived_at + MAX_BROADCAST_DURATION
      max_hours = (MAX_BROADCAST_DURATION / 1.hour).to_i
      errors.add(:leaving_at, "cannot be more than #{max_hours} hours after arrival")
    end
  end

  def update_stats
    # UpdateSellerStatsJob.perform_later(id) # Will implement with Sidekiq later
  end

  def notify_followers(event_type)
    # SendPushNotificationJob.perform_later(...) # Will implement with Sidekiq later
  end
end
