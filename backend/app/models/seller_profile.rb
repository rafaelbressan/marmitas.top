class SellerProfile < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :dishes, dependent: :destroy
  has_many :weekly_menus, dependent: :destroy
  # TODO: Uncomment when models are created
  # has_many :selling_locations, dependent: :destroy
  # has_many :favorites, dependent: :destroy
  # has_many :followers, through: :favorites, source: :user
  # has_many :reviews, dependent: :destroy
  # has_many :activity_logs, dependent: :destroy

  # Active Storage
  has_one_attached :profile_photo
  has_many_attached :gallery_photos

  # Validations
  validates :business_name, presence: true
  validates :user_id, uniqueness: true

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(currently_active: true) }
  scope :in_city, ->(city) { where(city: city) }
  # TODO: Uncomment when selling_locations model is created
  # scope :nearby, ->(lat, lng, radius_km = 5) {
  #   joins(:selling_locations)
  #     .where(currently_active: true)
  #     .where(
  #       "ST_DWithin(
  #         ST_MakePoint(selling_locations.longitude, selling_locations.latitude)::geography,
  #         ST_MakePoint(?, ?)::geography,
  #         ?
  #       )",
  #       lng, lat, radius_km * 1000
  #     )
  #     .distinct
  # }

  # Callbacks
  after_commit :update_stats, on: [:create, :update]

  # Methods
  def current_menu
    weekly_menus.available_now.first
  end

  # TODO: Uncomment when selling_locations model is created
  # def current_location
  #   return nil unless current_menu
  #   selling_locations.find_by(id: current_menu.selling_location_id)
  # end

  # def announce_arrival(location_id)
  #   transaction do
  #     update!(currently_active: true, last_active_at: Time.current)
  #     activity_logs.create!(
  #       activity_type: 'arrived',
  #       selling_location_id: location_id,
  #       occurred_at: Time.current
  #     )
  #     notify_followers(:arrival)
  #   end
  # end

  # def announce_departure
  #   transaction do
  #     update!(currently_active: false)
  #     activity_logs.create!(
  #       activity_type: 'departed',
  #       occurred_at: Time.current
  #     )
  #     notify_followers(:departure)
  #   end
  # end

  private

  def update_stats
    # UpdateSellerStatsJob.perform_later(id) # Will implement with Sidekiq later
  end

  def notify_followers(event_type)
    # SendPushNotificationJob.perform_later(...) # Will implement with Sidekiq later
  end
end
