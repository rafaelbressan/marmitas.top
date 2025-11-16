class Review < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :seller_profile, counter_cache: :reviews_count
  belongs_to :weekly_menu, optional: true
  belongs_to :moderated_by, class_name: 'User', optional: true

  has_many :review_helpfuls, dependent: :destroy

  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :encounter_date, presence: true
  validates :comment, presence: true, if: :extreme_rating?

  # Unique constraint: one review per user per seller per day
  validates :user_id, uniqueness: {
    scope: [:seller_profile_id, :encounter_date],
    message: "Você já avaliou este marmiteiro hoje"
  }

  # Custom validations
  validate :cannot_review_own_business
  validate :cannot_edit_after_window, on: :update
  validate :cannot_edit_under_moderation, on: :update

  # Scopes
  scope :published, -> { where(moderation_status: 'published') }
  scope :flagged_reviews, -> { where(flagged: true) }
  scope :under_review, -> { where(moderation_status: 'under_review') }
  scope :removed, -> { where(moderation_status: 'removed') }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :medium, -> { where(created_at: 90.days.ago..30.days.ago) }
  scope :old, -> { where('created_at < ?', 90.days.ago) }
  scope :verified, -> { where(verified_encounter: true) }
  scope :with_comments, -> { where.not(comment: [nil, '']) }
  scope :by_rating, ->(rating) { where(rating: rating) }

  # Callbacks
  before_validation :set_encounter_date, on: :create
  before_create :snapshot_dish_name
  before_create :verify_encounter_location
  before_create :detect_suspicious_patterns
  after_save :update_seller_rating
  after_destroy :update_seller_rating

  # Class methods
  def self.rating_distribution(seller_profile_id)
    where(seller_profile_id: seller_profile_id, moderation_status: 'published')
      .group(:rating)
      .count
  end

  # Instance methods

  # Check if user marked this review as helpful
  def helpful_by?(user)
    review_helpfuls.exists?(user: user)
  end

  # Toggle helpful vote
  def toggle_helpful(user)
    return false if user.id == self.user_id # Can't mark own review as helpful

    helpful = review_helpfuls.find_by(user: user)

    if helpful
      helpful.destroy
      decrement!(:helpful_count)
      false
    else
      review_helpfuls.create!(user: user)
      increment!(:helpful_count)
      true
    end
  end

  # Check if review can be edited
  def editable_by?(current_user)
    return false unless current_user.id == user_id
    return false if moderation_status == 'under_review'
    return false if moderation_status == 'removed'
    return false unless within_edit_window?

    true
  end

  # Check if within 48-hour edit window
  def within_edit_window?
    created_at > 48.hours.ago
  end

  # Check if review can be flagged
  def flaggable_by?(current_user)
    return false if current_user.id == user_id # Can't flag own review
    return false if flagged? # Already flagged
    return false unless moderation_status == 'published'

    true
  end

  # Flag review for moderation
  def flag!(reason, flagged_by_user)
    return false unless flaggable_by?(flagged_by_user)

    update!(
      flagged: true,
      flag_reason: reason,
      moderation_status: 'under_review'
    )

    # Trigger moderation alert job
    SendModerationAlertJob.perform_later(id)

    true
  end

  # Admin moderation actions
  def approve!(admin, note = nil)
    update!(
      moderation_status: 'published',
      flagged: false,
      moderation_note: note,
      moderated_at: Time.current,
      moderated_by: admin
    )
  end

  def remove!(admin, note)
    raise ArgumentError, "Note is required when removing review" if note.blank?

    update!(
      moderation_status: 'removed',
      moderation_note: note,
      moderated_at: Time.current,
      moderated_by: admin
    )
  end

  # Display dish name (handles deleted menus)
  def display_dish_name
    if weekly_menu&.deleted_at?
      "#{dish_name} (não disponível)"
    else
      dish_name || weekly_menu&.dishes&.first&.[]('name') || 'Menu da semana'
    end
  end

  private

  def extreme_rating?
    rating == 1 || rating == 5
  end

  def cannot_review_own_business
    if user&.seller_profile && user.seller_profile.id == seller_profile_id
      errors.add(:base, "Você não pode avaliar seu próprio negócio")
    end
  end

  def cannot_edit_after_window
    if persisted? && !within_edit_window? && (rating_changed? || comment_changed?)
      errors.add(:base, "Esta avaliação não pode mais ser editada (prazo de 48h expirado)")
    end
  end

  def cannot_edit_under_moderation
    if persisted? && moderation_status == 'under_review' && (rating_changed? || comment_changed?)
      errors.add(:base, "Esta avaliação está sob moderação e não pode ser editada")
    end
  end

  def set_encounter_date
    self.encounter_date ||= Date.current
  end

  def snapshot_dish_name
    if weekly_menu
      # Capture dish names from the weekly menu's dishes array
      dishes = weekly_menu.dishes || []
      self.dish_name ||= dishes.map { |d| d['name'] }.join(', ') if dishes.any?
    end
  end

  def verify_encounter_location
    return unless encounter_latitude.present? && encounter_longitude.present?
    return unless seller_profile.currently_active?
    return unless seller_profile.current_location

    # Calculate distance between user and seller
    seller_location = seller_profile.current_location
    distance = Geocoder::Calculations.distance_between(
      [encounter_latitude, encounter_longitude],
      [seller_location.latitude, seller_location.longitude],
      units: :km
    )

    # Mark as verified if within 50 meters
    self.verified_encounter = (distance <= 0.05)
  end

  def detect_suspicious_patterns
    # Check for spam patterns
    recent_reviews = user.reviews.where('created_at > ?', 7.days.ago).where.not(id: id)

    # Pattern 1: Too many one-star reviews
    one_star_count = recent_reviews.where(rating: 1).count
    if rating == 1 && one_star_count >= 2
      self.moderation_status = 'under_review'
      self.flag_reason = "Auto-flagged: Padrão suspeito de avaliações negativas"
    end

    # Pattern 2: Too many reviews in short time
    if recent_reviews.count >= 9 # 10+ including current
      self.moderation_status = 'under_review'
      self.flag_reason = "Auto-flagged: Muitas avaliações em curto período"
    end
  end

  def update_seller_rating
    seller_profile.recalculate_ratings!
  end
end
