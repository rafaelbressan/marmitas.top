class Order < ApplicationRecord
  # Status constants
  STATUSES = %w[pending confirmed completed cancelled expired].freeze

  # Associations
  belongs_to :user, counter_cache: true
  belongs_to :seller_profile, counter_cache: :total_orders_count
  belongs_to :weekly_menu, optional: true
  has_many :order_items, dependent: :destroy
  has_many :dishes, through: :order_items
  belongs_to :moderated_by, class_name: 'User', optional: true

  # Validations
  validates :status, inclusion: { in: STATUSES }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :order_date, presence: true
  validates :completion_code, presence: true, length: { is: 6 }

  # Custom validations
  validate :cannot_order_from_self, on: :create
  validate :seller_must_be_active, on: :create
  validate :must_have_order_items, on: :create
  validate :total_matches_items_sum, on: :create

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :expired, -> { where(status: 'expired') }
  scope :active, -> { where(status: %w[pending confirmed]) }
  scope :awaiting_pickup, -> { confirmed.where('pickup_expires_at > ?', Time.current) }
  scope :recent, -> { order(order_date: :desc) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_seller, ->(seller_id) { where(seller_profile_id: seller_id) }
  scope :today, -> { where('order_date >= ?', Time.current.beginning_of_day) }

  # Callbacks
  before_validation :set_order_date, on: :create
  before_validation :generate_completion_code, on: :create
  before_validation :snapshot_seller_location, on: :create
  before_validation :snapshot_customer_location, on: :create
  before_create :decrement_quantities!
  after_update :set_pickup_expires_at, if: :saved_change_to_confirmed_at?
  after_update :increment_completed_counter, if: -> { saved_change_to_status? && completed? }
  after_update :restore_quantities_if_cancelled_or_expired, if: :saved_change_to_status?
  after_destroy :restore_quantities!

  # State transition methods
  def confirm!
    return false unless pending?

    transaction do
      update!(
        status: 'confirmed',
        confirmed_at: Time.current
      )
    end

    true
  end

  def complete!(validation_code)
    return false unless confirmed?
    return false unless completion_code == validation_code

    update!(
      status: 'completed',
      completed_at: Time.current
    )

    true
  end

  def cancel!(reason = nil)
    return false unless can_cancel?

    transaction do
      update!(
        status: 'cancelled',
        cancelled_at: Time.current,
        cancellation_reason: reason
      )
    end

    true
  end

  def expire!
    return false if completed? || cancelled? || expired?

    transaction do
      update!(
        status: 'expired',
        expired_at: Time.current
      )
    end

    true
  end

  # Query methods
  def can_cancel?
    return false if completed? || expired?
    return true if pending? || confirmed?
    false
  end

  def expired?
    status == 'expired'
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def pending?
    status == 'pending'
  end

  def confirmed?
    status == 'confirmed'
  end

  def awaiting_pickup?
    confirmed? && pickup_expires_at && pickup_expires_at > Time.current
  end

  def pickup_expired?
    pickup_expires_at && pickup_expires_at < Time.current
  end

  def editable_by?(current_user)
    return false unless current_user
    seller_profile.user_id == current_user.id
  end

  private

  def set_order_date
    self.order_date ||= Time.current
  end

  def generate_completion_code
    self.completion_code ||= SecureRandom.random_number(999999).to_s.rjust(6, '0')
  end

  def snapshot_seller_location
    return unless seller_profile&.current_location

    location = seller_profile.current_location
    self.seller_location_name = location.name
    self.seller_latitude = location.latitude
    self.seller_longitude = location.longitude
  end

  def snapshot_customer_location
    # This would be set from params in controller
    # Just ensuring we have the fields available
  end

  def cannot_order_from_self
    if user&.seller_profile && user.seller_profile.id == seller_profile_id
      errors.add(:base, "Você não pode fazer pedidos do seu próprio negócio")
    end
  end

  def seller_must_be_active
    if seller_profile && !seller_profile.currently_active?
      errors.add(:seller_profile, "não está ativo no momento")
    end
  end

  def must_have_order_items
    if order_items.empty? && new_record?
      errors.add(:base, "Pedido deve ter pelo menos um item")
    end
  end

  def total_matches_items_sum
    return if order_items.empty?

    items_total = order_items.sum(&:subtotal)
    expected_total = items_total + (delivery_fee || 0)

    if total_price != expected_total
      errors.add(:total_price, "não corresponde à soma dos itens (esperado: #{expected_total})")
    end
  end

  def decrement_quantities!
    order_items.each do |item|
      menu_dish = item.weekly_menu_dish
      next unless menu_dish

      unless menu_dish.remaining_quantity >= item.quantity
        raise ActiveRecord::RecordInvalid.new(self)
      end

      menu_dish.update!(remaining_quantity: menu_dish.remaining_quantity - item.quantity)
    end
  end

  def restore_quantities!
    order_items.each do |item|
      menu_dish = item.weekly_menu_dish
      next unless menu_dish

      menu_dish.update!(remaining_quantity: menu_dish.remaining_quantity + item.quantity)
    end
  end

  def restore_quantities_if_cancelled_or_expired
    restore_quantities! if cancelled? || expired?
  end

  def set_pickup_expires_at
    return unless confirmed_at && seller_profile

    grace_period = seller_profile.grace_period_minutes || 30
    self.pickup_expires_at = confirmed_at + grace_period.minutes
    save if pickup_expires_at_changed?
  end

  def increment_completed_counter
    seller_profile.increment!(:completed_orders_count)
  end
end
