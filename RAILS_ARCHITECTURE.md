# Rails 8 Backend Architecture

**Project:** Marmitas.top API
**Rails Version:** 8.0+
**Ruby Version:** 3.2+

## Table of Contents
- [Directory Structure](#directory-structure)
- [Models & Associations](#models--associations)
- [Controllers](#controllers)
- [Services](#services)
- [Jobs](#jobs)
- [Policies (Authorization)](#policies-authorization)
- [Serializers](#serializers)
- [Database Considerations](#database-considerations)
- [Testing Strategy](#testing-strategy)

---

## Directory Structure

```
backend/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── auth_controller.rb
│   │   │       ├── marmiteiros_controller.rb
│   │   │       ├── favorites_controller.rb
│   │   │       ├── reviews_controller.rb
│   │   │       └── marmiteiro/
│   │   │           ├── profiles_controller.rb
│   │   │           ├── menus_controller.rb
│   │   │           ├── locations_controller.rb
│   │   │           └── activities_controller.rb
│   │   └── application_controller.rb
│   │
│   ├── models/
│   │   ├── user.rb
│   │   ├── marmiteiro_profile.rb
│   │   ├── selling_location.rb
│   │   ├── daily_menu.rb
│   │   ├── favorite.rb
│   │   ├── review.rb
│   │   ├── activity_log.rb
│   │   ├── device_token.rb
│   │   └── concerns/
│   │       ├── geolocatable.rb
│   │       └── notifiable.rb
│   │
│   ├── services/
│   │   ├── auth/
│   │   │   ├── jwt_encoder.rb
│   │   │   └── jwt_decoder.rb
│   │   ├── location/
│   │   │   ├── nearby_search.rb
│   │   │   └── geocoding_service.rb
│   │   ├── notifications/
│   │   │   ├── push_notification_service.rb
│   │   │   └── notification_builder.rb
│   │   └── activity/
│   │       ├── arrival_announcer.rb
│   │       └── departure_announcer.rb
│   │
│   ├── jobs/
│   │   ├── send_push_notification_job.rb
│   │   ├── update_marmiteiro_stats_job.rb
│   │   └── cleanup_old_menus_job.rb
│   │
│   ├── policies/
│   │   ├── application_policy.rb
│   │   ├── marmiteiro_profile_policy.rb
│   │   ├── daily_menu_policy.rb
│   │   ├── review_policy.rb
│   │   └── selling_location_policy.rb
│   │
│   ├── serializers/
│   │   ├── user_serializer.rb
│   │   ├── marmiteiro_serializer.rb
│   │   ├── daily_menu_serializer.rb
│   │   ├── review_serializer.rb
│   │   └── location_serializer.rb
│   │
│   ├── channels/
│   │   ├── application_cable/
│   │   │   ├── channel.rb
│   │   │   └── connection.rb
│   │   ├── marmiteiros_channel.rb
│   │   ├── favorites_channel.rb
│   │   └── notifications_channel.rb
│   │
│   └── mailers/
│       └── user_mailer.rb
│
├── config/
│   ├── routes.rb
│   ├── database.yml
│   ├── cable.yml
│   ├── credentials.yml.enc
│   └── initializers/
│       ├── devise.rb
│       ├── cors.rb
│       └── geocoder.rb
│
├── db/
│   ├── migrate/
│   ├── seeds.rb
│   └── schema.rb
│
├── lib/
│   └── tasks/
│
├── spec/
│   ├── models/
│   ├── requests/
│   ├── services/
│   └── factories/
│
├── Gemfile
├── Gemfile.lock
└── README.md
```

---

## Models & Associations

### User Model
```ruby
# app/models/user.rb

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum role: { consumer: 'consumer', marmiteiro: 'marmiteiro', admin: 'admin' }

  # Associations
  has_one :marmiteiro_profile, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_marmiteiros, through: :favorites, source: :marmiteiro_profile
  has_many :reviews, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :role, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :consumers, -> { where(role: 'consumer') }
  scope :marmiteiros, -> { where(role: 'marmiteiro') }

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

  def generate_jwt
    JWT.encode(
      { user_id: id, exp: 7.days.from_now.to_i },
      Rails.application.credentials.jwt_secret_key
    )
  end
end
```

### MarmiteiroProfile Model
```ruby
# app/models/marmiteiro_profile.rb

class MarmiteiroProfile < ApplicationRecord
  include Notifiable

  # Associations
  belongs_to :user
  has_many :selling_locations, dependent: :destroy
  has_many :daily_menus, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :followers, through: :favorites, source: :user
  has_many :reviews, dependent: :destroy
  has_many :activity_logs, dependent: :destroy

  # Active Storage
  has_one_attached :profile_photo
  has_many_attached :gallery_photos

  # Validations
  validates :business_name, presence: true
  validates :user_id, uniqueness: true

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(currently_active: true) }
  scope :nearby, ->(lat, lng, radius_km = 5) {
    joins(:selling_locations)
      .where(currently_active: true)
      .where(
        "ST_DWithin(
          ST_MakePoint(selling_locations.longitude, selling_locations.latitude)::geography,
          ST_MakePoint(?, ?)::geography,
          ?
        )",
        lng, lat, radius_km * 1000
      )
      .distinct
  }

  # Callbacks
  after_commit :update_stats, on: [:create, :update]

  # Methods
  def current_menu
    daily_menus.where(menu_date: Date.today, active: true).first
  end

  def current_location
    selling_locations.where(id: current_menu&.selling_location_id).first
  end

  def announce_arrival(location_id)
    transaction do
      update!(currently_active: true, last_active_at: Time.current)
      activity_logs.create!(
        activity_type: 'arrived',
        selling_location_id: location_id,
        occurred_at: Time.current
      )
      notify_followers(:arrival)
    end
  end

  def announce_departure
    transaction do
      update!(currently_active: false)
      activity_logs.create!(
        activity_type: 'departed',
        occurred_at: Time.current
      )
      notify_followers(:departure)
    end
  end

  private

  def update_stats
    UpdateMarmiteiroStatsJob.perform_later(id)
  end

  def notify_followers(event_type)
    SendPushNotificationJob.perform_later(
      follower_ids: followers.pluck(:id),
      notification_type: event_type,
      marmiteiro_id: id
    )
  end
end
```

### SellingLocation Model
```ruby
# app/models/selling_location.rb

class SellingLocation < ApplicationRecord
  include Geolocatable

  # Associations
  belongs_to :marmiteiro_profile
  has_many :daily_menus

  # Validations
  validates :name, :latitude, :longitude, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  # Callbacks
  before_save :geocode_address, if: :address_changed?

  # Scopes
  scope :regular, -> { where(is_regular_spot: true) }

  # Methods
  def increment_usage!
    increment!(:times_used)
  end

  def distance_to(lat, lng)
    # Using Haversine formula via geocoder gem
    Geocoder::Calculations.distance_between(
      [latitude, longitude],
      [lat, lng],
      units: :km
    )
  end

  private

  def geocode_address
    return unless address.present?

    result = Geocoder.search(address).first
    if result
      self.latitude = result.latitude
      self.longitude = result.longitude
    end
  end
end
```

### DailyMenu Model
```ruby
# app/models/daily_menu.rb

class DailyMenu < ApplicationRecord
  # Associations
  belongs_to :marmiteiro_profile
  belongs_to :selling_location, optional: true

  # Active Storage
  has_many_attached :photos

  # Validations
  validates :menu_date, :dish_name, :price, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :total_quantity, :remaining_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :today, -> { where(menu_date: Date.today) }
  scope :active, -> { where(active: true) }
  scope :available, -> { where('remaining_quantity IS NULL OR remaining_quantity > 0') }

  # Methods
  def sold_out?
    remaining_quantity.present? && remaining_quantity <= 0
  end

  def low_stock?
    return false unless total_quantity && remaining_quantity
    (remaining_quantity.to_f / total_quantity) <= 0.2
  end

  def activate!(location_id)
    update!(
      active: true,
      activated_at: Time.current,
      selling_location_id: location_id
    )
  end

  def deactivate!
    update!(active: false, deactivated_at: Time.current)
  end

  def update_quantity!(new_quantity)
    update!(remaining_quantity: new_quantity)
    notify_if_low_stock
  end

  private

  def notify_if_low_stock
    return unless low_stock?

    SendPushNotificationJob.perform_later(
      follower_ids: marmiteiro_profile.followers.pluck(:id),
      notification_type: :low_stock,
      menu_id: id
    )
  end
end
```

### Favorite Model
```ruby
# app/models/favorite.rb

class Favorite < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :marmiteiro_profile, counter_cache: :followers_count

  # Validations
  validates :user_id, uniqueness: { scope: :marmiteiro_profile_id }

  # Callbacks
  after_create :send_new_follower_notification

  private

  def send_new_follower_notification
    SendPushNotificationJob.perform_later(
      user_ids: [marmiteiro_profile.user_id],
      notification_type: :new_follower,
      data: { follower_name: user.name }
    )
  end
end
```

### Review Model
```ruby
# app/models/review.rb

class Review < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :marmiteiro_profile, counter_cache: :reviews_count

  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :marmiteiro_profile_id, message: "can only review once" }

  # Callbacks
  after_commit :update_marmiteiro_rating, on: [:create, :update, :destroy]

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :top_rated, -> { where(rating: 4..5) }

  private

  def update_marmiteiro_rating
    avg = marmiteiro_profile.reviews.average(:rating)
    marmiteiro_profile.update_column(:average_rating, avg || 0.0)
  end
end
```

---

## Controllers

### Base API Controller
```ruby
# app/controllers/api/v1/base_controller.rb

module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from Pundit::NotAuthorizedError, with: :forbidden

      private

      def authenticate_user!
        token = request.headers['Authorization']&.split(' ')&.last
        decoded = Services::Auth::JwtDecoder.call(token)

        @current_user = User.find(decoded[:user_id])
      rescue => e
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end

      attr_reader :current_user

      def not_found
        render json: { error: 'Resource not found' }, status: :not_found
      end

      def forbidden
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
```

### Marmiteiros Controller
```ruby
# app/controllers/api/v1/marmiteiros_controller.rb

module Api
  module V1
    class MarmiteirosController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :nearby]

      def index
        @marmiteiros = MarmiteiroProfile.verified
        @marmiteiros = apply_filters(@marmiteiros)
        @marmiteiros = @marmiteiros.page(params[:page])

        render json: MarmiteiroSerializer.new(@marmiteiros).serializable_hash
      end

      def show
        @marmiteiro = MarmiteiroProfile.find(params[:id])
        render json: MarmiteiroSerializer.new(@marmiteiro, include_menu: true).serializable_hash
      end

      def nearby
        lat = params[:latitude].to_f
        lng = params[:longitude].to_f
        radius = params[:radius]&.to_f || 5.0

        @marmiteiros = MarmiteiroProfile.nearby(lat, lng, radius)
        render json: MarmiteiroSerializer.new(@marmiteiros).serializable_hash
      end

      private

      def apply_filters(scope)
        scope = scope.where(city: params[:city]) if params[:city].present?
        scope = scope.where('average_rating >= ?', params[:min_rating]) if params[:min_rating].present?
        scope
      end
    end
  end
end
```

### Marmiteiro Menu Controller
```ruby
# app/controllers/api/v1/marmiteiro/menus_controller.rb

module Api
  module V1
    module Marmiteiro
      class MenusController < BaseController
        before_action :ensure_marmiteiro!
        before_action :set_profile

        def index
          @menus = @profile.daily_menus.order(menu_date: :desc).page(params[:page])
          render json: DailyMenuSerializer.new(@menus).serializable_hash
        end

        def create
          @menu = @profile.daily_menus.build(menu_params)
          authorize @menu

          if @menu.save
            render json: DailyMenuSerializer.new(@menu).serializable_hash, status: :created
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          @menu = @profile.daily_menus.find(params[:id])
          authorize @menu

          if @menu.update(menu_params)
            render json: DailyMenuSerializer.new(@menu).serializable_hash
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def ensure_marmiteiro!
          render json: { error: 'Forbidden' }, status: :forbidden unless current_user.marmiteiro?
        end

        def set_profile
          @profile = current_user.marmiteiro_profile
        end

        def menu_params
          params.require(:daily_menu).permit(
            :menu_date, :dish_name, :description, :price,
            :total_quantity, :remaining_quantity, :food_type,
            dietary_tags: [], photos: []
          )
        end
      end
    end
  end
end
```

---

## Services

### Nearby Search Service
```ruby
# app/services/location/nearby_search.rb

module Services
  module Location
    class NearbySearch
      def initialize(latitude:, longitude:, radius_km: 5, filters: {})
        @latitude = latitude
        @longitude = longitude
        @radius_km = radius_km
        @filters = filters
      end

      def call
        query = build_query
        execute_query(query)
      end

      private

      def build_query
        # Using PostGIS geography type for accurate distance calculation
        <<-SQL
          SELECT
            mp.*,
            sl.latitude,
            sl.longitude,
            ST_Distance(
              ST_MakePoint(sl.longitude, sl.latitude)::geography,
              ST_MakePoint(?, ?)::geography
            ) / 1000 as distance_km
          FROM marmiteiro_profiles mp
          JOIN daily_menus dm ON dm.marmiteiro_profile_id = mp.id
          JOIN selling_locations sl ON sl.id = dm.selling_location_id
          WHERE mp.currently_active = true
            AND dm.active = true
            AND dm.menu_date = ?
            AND ST_DWithin(
              ST_MakePoint(sl.longitude, sl.latitude)::geography,
              ST_MakePoint(?, ?)::geography,
              ?
            )
          ORDER BY distance_km
        SQL
      end

      def execute_query(query)
        MarmiteiroProfile.find_by_sql([
          query,
          @longitude, @latitude,
          Date.today,
          @longitude, @latitude,
          @radius_km * 1000
        ])
      end
    end
  end
end
```

### Push Notification Service
```ruby
# app/services/notifications/push_notification_service.rb

module Services
  module Notifications
    class PushNotificationService
      def initialize(user_ids:, notification_type:, data: {})
        @user_ids = user_ids
        @notification_type = notification_type
        @data = data
      end

      def call
        tokens = DeviceToken.where(user_id: @user_ids).pluck(:token, :platform)

        tokens.each do |token, platform|
          send_notification(token, platform)
        end
      end

      private

      def send_notification(token, platform)
        fcm = FCM.new(Rails.application.credentials.fcm_server_key)

        payload = {
          notification: notification_payload,
          data: @data,
          token: token
        }

        fcm.send_v1(payload)
      rescue => e
        Rails.logger.error("Push notification failed: #{e.message}")
      end

      def notification_payload
        case @notification_type
        when :arrival
          { title: "#{@data[:marmiteiro_name]} chegou!", body: "Confira o cardápio de hoje" }
        when :departure
          { title: "#{@data[:marmiteiro_name]} foi embora", body: "Até a próxima!" }
        when :low_stock
          { title: "Últimas unidades!", body: "Apenas #{@data[:remaining]} marmitas restantes" }
        else
          { title: "Nova notificação", body: "" }
        end
      end
    end
  end
end
```

---

## Jobs

### Send Push Notification Job
```ruby
# app/jobs/send_push_notification_job.rb

class SendPushNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(user_ids:, notification_type:, data: {})
    Services::Notifications::PushNotificationService.new(
      user_ids: user_ids,
      notification_type: notification_type,
      data: data
    ).call
  end
end
```

### Cleanup Old Menus Job
```ruby
# app/jobs/cleanup_old_menus_job.rb

class CleanupOldMenusJob < ApplicationJob
  queue_as :maintenance

  def perform
    # Deactivate menus older than 1 day
    DailyMenu.where('menu_date < ?', Date.yesterday)
             .where(active: true)
             .update_all(active: false, deactivated_at: Time.current)
  end
end
```

---

## Policies (Authorization)

### Daily Menu Policy
```ruby
# app/policies/daily_menu_policy.rb

class DailyMenuPolicy < ApplicationPolicy
  def create?
    user.marmiteiro? && user.marmiteiro_profile.present?
  end

  def update?
    user.marmiteiro? && record.marmiteiro_profile.user_id == user.id
  end

  def destroy?
    update?
  end
end
```

---

## Serializers

### Marmiteiro Serializer
```ruby
# app/serializers/marmiteiro_serializer.rb

class MarmiteiroSerializer
  def initialize(resource, options = {})
    @resource = resource
    @options = options
  end

  def serializable_hash
    if @resource.respond_to?(:each)
      { data: @resource.map { |r| serialize_one(r) } }
    else
      { data: serialize_one(@resource) }
    end
  end

  private

  def serialize_one(marmiteiro)
    {
      id: marmiteiro.id,
      type: 'marmiteiro',
      attributes: {
        business_name: marmiteiro.business_name,
        bio: marmiteiro.bio,
        city: marmiteiro.city,
        average_rating: marmiteiro.average_rating,
        reviews_count: marmiteiro.reviews_count,
        followers_count: marmiteiro.followers_count,
        currently_active: marmiteiro.currently_active,
        profile_photo_url: marmiteiro.profile_photo.attached? ? rails_blob_url(marmiteiro.profile_photo) : nil
      },
      relationships: relationships(marmiteiro)
    }
  end

  def relationships(marmiteiro)
    rel = {}
    rel[:current_menu] = DailyMenuSerializer.new(marmiteiro.current_menu).serializable_hash if @options[:include_menu]
    rel
  end
end
```

---

## Database Considerations

### PostGIS Setup
```ruby
# db/migrate/20250101000000_enable_postgis.rb

class EnablePostgis < ActiveRecord::Migration[8.0]
  def up
    enable_extension 'postgis'
  end

  def down
    disable_extension 'postgis'
  end
end
```

### Geospatial Indexes
```ruby
# db/migrate/20250101000001_add_geospatial_indexes.rb

class AddGeospatialIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :selling_locations,
              "ST_MakePoint(longitude, latitude)::geography",
              using: :gist,
              name: 'index_selling_locations_on_geography'
  end
end
```

---

## Testing Strategy

### RSpec Setup
```ruby
# Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
end
```

### Model Test Example
```ruby
# spec/models/marmiteiro_profile_spec.rb

require 'rails_helper'

RSpec.describe MarmiteiroProfile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:daily_menus) }
    it { should have_many(:favorites) }
  end

  describe 'validations' do
    it { should validate_presence_of(:business_name) }
  end

  describe '#announce_arrival' do
    let(:profile) { create(:marmiteiro_profile) }
    let(:location) { create(:selling_location, marmiteiro_profile: profile) }

    it 'updates currently_active status' do
      profile.announce_arrival(location.id)
      expect(profile.currently_active).to be true
    end

    it 'creates an activity log' do
      expect {
        profile.announce_arrival(location.id)
      }.to change(ActivityLog, :count).by(1)
    end
  end
end
```

### Request Test Example
```ruby
# spec/requests/api/v1/marmiteiros_spec.rb

require 'rails_helper'

RSpec.describe 'Api::V1::Marmiteiros', type: :request do
  describe 'GET /api/v1/marmiteiros/nearby' do
    let!(:marmiteiro) { create(:marmiteiro_profile, :with_location, :active) }

    it 'returns nearby marmiteiros' do
      get '/api/v1/marmiteiros/nearby',
          params: { latitude: -22.9, longitude: -43.2, radius: 10 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
    end
  end
end
```

---

## Next Steps

1. **Initialize Rails App**
   ```bash
   rails new backend --api --database=postgresql --skip-test
   ```

2. **Install Core Gems**
   ```bash
   bundle add devise devise-jwt pundit geocoder sidekiq redis rack-cors
   ```

3. **Set Up Database**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Generate Models**
   ```bash
   rails g devise User
   rails g model MarmiteiroProfile user:references business_name:string ...
   ```

5. **Configure CORS**
   ```ruby
   # config/initializers/cors.rb
   Rails.application.config.middleware.insert_before 0, Rack::Cors do
     allow do
       origins 'localhost:8081', 'expo.dev'
       resource '*', headers: :any, methods: [:get, :post, :patch, :delete, :options]
     end
   end
   ```

6. **Set Up Testing**
   ```bash
   rails generate rspec:install
   ```

---

**Document Version:** 1.0
**Last Updated:** November 7, 2025
