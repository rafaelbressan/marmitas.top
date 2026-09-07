class Dish < ApplicationRecord
  include Discard::Model

  # Associations
  belongs_to :seller_profile
  # `dependent: :destroy` continua certo para uma destruicao de verdade, mas a
  # API nao destroi mais prato: `dishes#destroy` chama `discard`. Era isto que
  # apagava a linha do prato em todo cardapio passado — e com ela o
  # `available_quantity`/`remaining_quantity` daquele dia.
  has_many :weekly_menu_dishes, dependent: :destroy
  has_many :weekly_menus, through: :weekly_menu_dishes
  has_many :favorites, as: :favoritable, dependent: :destroy
  has_many :favorited_by, through: :favorites, source: :user

  # Active Storage
  has_many_attached :photos

  # Validations
  validates :name, presence: true
  validates :base_price, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { kept.where(active: true) }
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
