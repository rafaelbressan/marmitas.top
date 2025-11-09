class Dish < ApplicationRecord
  # Associations
  belongs_to :seller_profile
  has_many :weekly_menu_dishes, dependent: :destroy
  has_many :weekly_menus, through: :weekly_menu_dishes

  # Active Storage
  has_many_attached :photos

  # Validations
  validates :name, presence: true
  validates :base_price, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_seller, ->(seller_profile_id) { where(seller_profile_id: seller_profile_id) }

  # Dietary tags helpers
  DIETARY_TAGS = %w[vegan vegetarian gluten_free dairy_free nut_free halal kosher low_carb keto paleo].freeze

  def dietary_tags=(tags)
    super(Array(tags).select(&:present?))
  end

  # Check if dish has a specific dietary tag
  def has_dietary_tag?(tag)
    dietary_tags.include?(tag.to_s)
  end

  # Human-readable dietary tags
  def dietary_tags_display
    dietary_tags.map { |tag| tag.humanize }.join(', ')
  end
end
