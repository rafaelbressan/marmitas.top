class SellingLocation < ApplicationRecord
  # Associations
  belongs_to :seller_profile
  has_many :seller_profiles_using, class_name: 'SellerProfile', foreign_key: :current_location_id, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :maximum_locations_per_seller, on: :create

  # Scopes
  scope :for_seller, ->(seller_profile_id) { where(seller_profile_id: seller_profile_id) }

  # Methods
  def coordinates?
    latitude.present? && longitude.present?
  end

  def full_address
    [address, name].compact.join(' - ')
  end

  private

  def maximum_locations_per_seller
    if seller_profile.selling_locations.count >= 3
      errors.add(:base, "Cannot have more than 3 selling locations")
    end
  end
end
