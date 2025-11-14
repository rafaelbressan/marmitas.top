class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Associations
  has_one :seller_profile, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_dishes, -> { where(favorites: { favoritable_type: 'Dish' }) }, through: :favorites, source: :favoritable, source_type: 'Dish'
  has_many :favorited_sellers, -> { where(favorites: { favoritable_type: 'SellerProfile' }) }, through: :favorites, source: :favoritable, source_type: 'SellerProfile'
  has_many :reviews, dependent: :destroy
  has_many :review_helpfuls, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(is_admin: true) }
  scope :sellers, -> { joins(:seller_profile) }
  scope :with_seller_profile, -> { includes(:seller_profile).where.not(seller_profiles: { id: nil }) }

  # Methods
  def admin?
    is_admin
  end

  def seller?
    seller_profile.present?
  end

  def consumer?
    true # All users are consumers by default
  end

  # Check if user has favorited an item
  def favorited?(favoritable)
    favorites.exists?(favoritable: favoritable)
  end

  # Favorite an item
  def favorite!(favoritable)
    favorites.find_or_create_by!(favoritable: favoritable)
  end

  # Unfavorite an item
  def unfavorite!(favoritable)
    favorites.find_by(favoritable: favoritable)&.destroy
  end
end
