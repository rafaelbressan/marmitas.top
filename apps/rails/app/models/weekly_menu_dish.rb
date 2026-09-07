class WeeklyMenuDish < ApplicationRecord
  # Associations
  belongs_to :weekly_menu
  belongs_to :dish

  # Validations
  validates :available_quantity, presence: true, numericality: { greater_than: 0 }
  validates :remaining_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :dish_id, uniqueness: { scope: :weekly_menu_id, message: "already added to this menu" }
  validate :remaining_not_greater_than_available

  # Callbacks
  before_validation :set_remaining_quantity, on: :create

  # Scopes
  scope :available, -> { where('remaining_quantity > 0') }
  scope :ordered, -> { order(:display_order, :created_at) }

  # Get effective price (override or base price)
  def effective_price
    price_override || dish.base_price
  end

  # Check if dish is still available
  def available?
    remaining_quantity > 0
  end

  # Decrease remaining quantity when an order is placed
  def decrease_quantity!(amount = 1)
    if remaining_quantity >= amount
      update!(remaining_quantity: remaining_quantity - amount)
      true
    else
      false
    end
  end

  # Increase remaining quantity (e.g., order cancelled)
  def increase_quantity!(amount = 1)
    new_quantity = remaining_quantity + amount
    if new_quantity <= available_quantity
      update!(remaining_quantity: new_quantity)
      true
    else
      false
    end
  end

  private

  def set_remaining_quantity
    self.remaining_quantity ||= available_quantity
  end

  def remaining_not_greater_than_available
    return if remaining_quantity.blank? || available_quantity.blank?

    if remaining_quantity > available_quantity
      errors.add(:remaining_quantity, "cannot be greater than available quantity")
    end
  end
end
