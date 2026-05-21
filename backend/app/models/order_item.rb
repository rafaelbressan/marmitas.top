class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :dish
  belongs_to :weekly_menu_dish, optional: true

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :subtotal, presence: true, numericality: { greater_than: 0 }
  validates :dish_name_snapshot, presence: true

  # Callbacks
  before_validation :calculate_subtotal
  before_validation :snapshot_dish_data

  private

  def calculate_subtotal
    return unless quantity && unit_price

    self.subtotal = quantity * unit_price
  end

  def snapshot_dish_data
    return unless dish

    self.dish_name_snapshot ||= dish.name
    self.dish_description_snapshot ||= dish.description
  end
end
