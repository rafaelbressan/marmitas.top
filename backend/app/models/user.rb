class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Enums
  ROLES = %w[consumer marmiteiro admin].freeze

  # Associations
  has_one :marmiteiro_profile, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_marmiteiros, through: :favorites, source: :marmiteiro_profile
  has_many :reviews, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :consumers, -> { where(role: 'consumer') }
  scope :marmiteiros, -> { where(role: 'marmiteiro') }
  scope :admins, -> { where(role: 'admin') }

  # Methods
  def consumer?
    role == 'consumer'
  end

  def marmiteiro?
    role == 'marmiteiro'
  end

  def admin?
    role == 'admin'
  end
end
