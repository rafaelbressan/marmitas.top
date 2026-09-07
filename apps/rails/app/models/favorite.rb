class Favorite < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :favoritable, polymorphic: true, counter_cache: true

  # Validations
  validates :user_id, uniqueness: { scope: [ :favoritable_type, :favoritable_id ], message: "already favorited this item" }

  # Scopes
  # O favorito nao e descartado (a pessoa refaz com um toque), mas some da lista
  # quando o prato ou o marmiteiro favoritado e descartado.
  scope :kept_favoritable, -> {
    where(favoritable_type: "Dish", favoritable_id: Dish.kept.select(:id))
      .or(where(favoritable_type: "SellerProfile", favoritable_id: SellerProfile.kept.select(:id)))
  }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :dishes, -> { where(favoritable_type: "Dish") }
  scope :sellers, -> { where(favoritable_type: "SellerProfile") }
end
