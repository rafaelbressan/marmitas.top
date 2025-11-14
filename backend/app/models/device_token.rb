class DeviceToken < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :token, presence: true
  validates :platform, presence: true, inclusion: { in: %w[ios android web] }
  validates :token, uniqueness: { scope: [:user_id, :platform] }

  # Callbacks
  before_save :update_last_used_at, if: :will_save_change_to_active?

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_platform, ->(platform) { where(platform: platform) }
  scope :ios, -> { where(platform: 'ios') }
  scope :android, -> { where(platform: 'android') }
  scope :web, -> { where(platform: 'web') }

  # Mark token as inactive (e.g., when user logs out)
  def deactivate!
    update!(active: false)
  end

  # Refresh last used timestamp
  def touch_last_used!
    update!(last_used_at: Time.current)
  end

  private

  def update_last_used_at
    self.last_used_at = Time.current if active?
  end
end
