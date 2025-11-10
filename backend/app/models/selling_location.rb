class SellingLocation < ApplicationRecord
  # Associations
  belongs_to :seller_profile
  has_many :seller_profiles_using, class_name: 'SellerProfile', foreign_key: :current_location_id, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :maximum_locations_per_seller, on: :create

  # Callbacks
  before_save :update_lonlat_from_coordinates, if: :coordinates_changed?

  # Scopes
  scope :for_seller, ->(seller_profile_id) { where(seller_profile_id: seller_profile_id) }
  scope :with_coordinates, -> { where.not(latitude: nil, longitude: nil) }

  # Methods
  def coordinates?
    latitude.present? && longitude.present?
  end

  def full_address
    [address, name].compact.join(' - ')
  end

  # Calculate distance from a point in kilometers
  def distance_from(lat, lng)
    return nil unless coordinates?

    # Use PostGIS ST_Distance for accurate spheroid calculations
    sql = <<-SQL
      SELECT ST_Distance(
        lonlat,
        ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
      ) / 1000.0 AS distance_km
    SQL

    result = self.class.connection.select_value(
      self.class.sanitize_sql_array([sql, lng, lat])
    )

    result&.to_f
  end

  private

  def maximum_locations_per_seller
    if seller_profile.selling_locations.count >= 3
      errors.add(:base, "Cannot have more than 3 selling locations")
    end
  end

  def coordinates_changed?
    latitude_changed? || longitude_changed?
  end

  def update_lonlat_from_coordinates
    if coordinates?
      # Update the PostGIS geography column
      self.lonlat = "SRID=4326;POINT(#{longitude} #{latitude})"
    else
      self.lonlat = nil
    end
  end
end
