class WeeklyMenu < ApplicationRecord
  include Discard::Model

  # Associations
  belongs_to :seller_profile
  has_many :weekly_menu_dishes, dependent: :destroy
  has_many :dishes, through: :weekly_menu_dishes
  has_many :reviews, dependent: :nullify  # Reviews persist even if menu is deleted

  # Validations
  validates :available_from, presence: true
  validates :available_until, presence: true
  validate :available_until_after_available_from

  # Scopes
  scope :active, -> { kept.where(active: true) }
  scope :for_seller, ->(seller_profile_id) { where(seller_profile_id: seller_profile_id) }
  scope :available_now, -> {
    where('available_from <= ? AND available_until >= ?', Time.current, Time.current)
      .where(active: true)
      .kept
  }
  scope :upcoming, -> {
    where('available_from > ?', Time.current)
      .where(active: true)
      .kept
      .order(available_from: :asc)
  }
  scope :past, -> {
    where('available_until < ?', Time.current)
      .kept
      .order(available_from: :desc)
  }

  # O soft delete artesanal (`deleted_at`, `soft_delete`, e um `destroy`
  # sobrescrito que so gravava a coluna) virou `Discard::Model`. O `destroy`
  # sobrescrito era a parte perigosa: pulava callbacks e `dependent:`, e
  # `menu.destroy` fazia coisa diferente do resto do app.

  # Check if menu is currently available
  def available?
    active && available_from <= Time.current && available_until >= Time.current
  end

  # Check if menu has any dishes
  def has_dishes?
    weekly_menu_dishes.kept.any?
  end

  # Get total available quantity across all dishes
  def total_available_quantity
    weekly_menu_dishes.kept.sum(:remaining_quantity)
  end

  # Duplicate menu for future use
  def duplicate(new_available_from: nil, new_available_until: nil)
    new_menu = self.dup
    new_menu.available_from = new_available_from || (available_from + 1.week)
    new_menu.available_until = new_available_until || (available_until + 1.week)
    new_menu.total_orders_count = 0
    new_menu.discarded_at = nil # `dup` copia a coluna; a copia nasce viva
    new_menu.active = false # Keep duplicated menu inactive by default

    transaction do
      new_menu.save!

      # Prato descartado nao volta para um cardapio novo — a linha antiga fica
      # onde esta, como registro do dia em que ele foi vendido.
      weekly_menu_dishes.kept.joins(:dish).merge(Dish.kept).each do |menu_dish|
        new_menu.weekly_menu_dishes.create!(
          dish_id: menu_dish.dish_id,
          available_quantity: menu_dish.available_quantity,
          remaining_quantity: menu_dish.available_quantity, # Reset remaining to full
          price_override: menu_dish.price_override,
          display_order: menu_dish.display_order
        )
      end
    end

    new_menu
  end

  # Generate WhatsApp message for sharing
  def whatsapp_message
    message = "🍱 *#{title || 'Cardápio da Semana'}* - #{seller_profile.business_name}\n\n"

    weekly_menu_dishes.ordered.each do |menu_dish|
      dish = menu_dish.dish
      price = menu_dish.price_override || dish.base_price
      message += "*#{dish.name}*\n"
      message += "#{dish.description}\n" if dish.description.present?
      message += "💰 R$ #{format('%.2f', price)}\n"
      message += "📦 #{menu_dish.remaining_quantity} disponíveis\n"

      if dish.dietary_tags.any?
        tags = dish.dietary_tags.map { |tag| "##{tag}" }.join(' ')
        message += "#{tags}\n"
      end

      message += "\n"
    end

    message += "📅 Disponível de #{available_from.strftime('%d/%m às %H:%M')} "
    message += "até #{available_until.strftime('%d/%m às %H:%M')}\n\n"
    message += "📍 #{seller_profile.city}, #{seller_profile.state}\n\n"
    message += "Peça já! 📲"

    message
  end

  private

  def available_until_after_available_from
    return if available_until.blank? || available_from.blank?

    if available_until <= available_from
      errors.add(:available_until, "must be after available from")
    end
  end
end
