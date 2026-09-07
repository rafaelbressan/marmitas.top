class Favorite < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :favoritable, polymorphic: true, counter_cache: true

  # Validations
  validates :user_id, uniqueness: { scope: [:favoritable_type, :favoritable_id], message: "already favorited this item" }

  # Scopes
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :dishes, -> { where(favoritable_type: 'Dish') }
  scope :sellers, -> { where(favoritable_type: 'SellerProfile') }
end
