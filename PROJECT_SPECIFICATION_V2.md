# Marmitas.top V2 - Project Specification

**Version:** 2.0
**Last Updated:** November 7, 2025
**Status:** Planning Phase

## Table of Contents
- [Overview](#overview)
- [User Personas](#user-personas)
- [Core Features](#core-features)
- [Technical Stack](#technical-stack)
- [Database Schema](#database-schema)
- [API Design](#api-design)
- [Real-time Features](#real-time-features)
- [Mobile App Features](#mobile-app-features)
- [Security & Privacy](#security--privacy)
- [Development Phases](#development-phases)

---

## Overview

Marmitas.top V2 transforms from a static list into a **dynamic, location-based marketplace** connecting food producers (marmiteiros) with consumers seeking affordable, homemade meals.

### The Problem
- Consumers struggle to find nearby, affordable homemade food options
- Marmiteiros lack a platform to reach customers and announce their daily offerings
- Traditional food delivery apps focus on restaurants, not individual food producers
- No real-time location tracking for street food vendors

### The Solution
A mobile-first platform where:
- Marmiteiros register, showcase weekly menus, and broadcast their location
- Consumers discover nearby options, follow favorites, and receive real-time notifications
- Map-based interface shows active marmiteiros in real-time
- Community-driven with ratings and reviews

---

## User Personas

### 1. Consumer (Buyer)
**Profile:** Office workers, students, remote workers looking for affordable, quality meals

**Needs:**
- Find nearby marmiteiros quickly
- See weekly menus and prices
- Follow favorite producers
- Get notified when favorites are nearby
- View ratings and reviews
- Save favorite locations

**User Journey:**
1. Opens app → sees map with nearby marmiteiros
2. Taps on marker → views producer profile, today's menu, price
3. Favorites interesting producers
4. Receives notification: "João's Marmitas is now at Praça XV!"
5. Navigates to location and purchases

### 2. Marmiteiro (Producer/Seller)
**Profile:** Home cooks, small food businesses, street vendors

**Needs:**
- Showcase daily offerings
- Announce location and arrival
- Build follower base
- Manage business hours and regular spots
- Receive customer feedback
- Update menu easily

**User Journey:**
1. Logs in → updates today's menu (dish, price, quantity)
2. Arrives at selling location → announces "I'm here!"
3. Followers receive notification
4. Updates status: "5 marmitas remaining"
5. Announces departure: "Sold out! See you tomorrow"

### 3. Admin (Platform Manager)
**Profile:** Platform moderators ensuring quality and safety

**Needs:**
- Verify marmiteiro accounts
- Handle reports and disputes
- Monitor platform health
- Manage featured producers

---

## Core Features

### For Consumers

#### 1. Discovery & Map
- **Interactive map** showing active marmiteiros in real-time
- Filter by:
  - Distance (nearby, 1km, 5km, 10km)
  - Price range
  - Food type (traditional, vegetarian, vegan, etc.)
  - Rating
- List view as alternative to map
- Search by name or location

#### 2. Producer Profiles
- Business name and photo
- Bio/description
- Regular selling locations
- Operating hours
- Average rating and review count
- Gallery of food photos
- Contact information (optional)

#### 3. Weekly Menu
- Weekly offerings (dish name, description)
- Price per portion
- Available quantity (live updates)
- Dietary information (vegan, vegetarian, gluten-free, etc.)
- Food photos

#### 4. Favorites & Following
- Follow favorite marmiteiros
- Quick access to favorites list
- Filter map to show only favorites

#### 5. Notifications
- "Your favorite marmiteiro is now active!"
- "Only 3 portions left at João's Marmitas"
- "João's Marmitas has left the location"
- Custom notification preferences

#### 6. Reviews & Ratings
- Rate producers (1-5 stars)
- Write text reviews
- Upload food photos
- Mark reviews as helpful

### For Marmiteiros

#### 1. Producer Dashboard
- Today's stats (views, favorites, notifications sent)
- Follower count
- Average rating
- Weekly/monthly insights

#### 2. Menu Management
- Quick "Post Today's Menu" flow
- Save favorite dishes for reuse
- Upload multiple photos
- Set available quantity
- Update real-time (e.g., "5 left", "Sold out")
- **Share to WhatsApp:**
  - "Copy Menu" button copies formatted menu text to clipboard
  - "Share on WhatsApp" button opens WhatsApp with pre-filled message
  - Formatted template: "🍱 Cardápio de Hoje - [Business Name]\n\n[Dish Name]\n💰 R$ [Price]\n📍 [Location]\n\n[Description]\n\nPeça já! 📲"
  - Essential for marmiteiros who use WhatsApp broadcast lists

#### 3. Location Management
- Add regular selling spots (saved locations)
- "I'm here!" quick action
  - Select saved location or use current GPS
  - Notifies all followers
  - Appears on map
- "I'm leaving!" action
  - Removes from active map
  - Updates followers

#### 4. Follower Engagement
- View follower count
- Send announcements (e.g., "Tomorrow: Feijoada!")
- Respond to reviews

#### 5. Business Profile
- Business name, photo, bio
- Operating schedule
- Contact methods (phone, WhatsApp)
- Payment methods accepted
- Gallery of past dishes

### Admin Features

#### 1. Moderation
- Review new marmiteiro registrations
- Verify business legitimacy
- Handle reported content
- Ban/suspend users if needed

#### 2. Analytics
- Platform usage stats
- Geographic heatmaps
- User growth metrics
- Top-rated producers

#### 3. Featured Content
- Promote quality producers
- Curated lists ("Top Rated This Week")

---

## Technical Stack

### Backend - Rails 8

**Framework:** Ruby on Rails 8.0+ (latest stable)

**Key Gems:**
- **devise** - Authentication & user management
- **devise-jwt** - JWT tokens for API authentication
- **pundit** - Authorization & permissions
- **active_storage** - File uploads (photos)
- **geocoder** - Address → coordinates conversion
- **pg** - PostgreSQL database
- **redis** - Caching & real-time subscriptions
- **action_cable** - WebSocket for real-time updates
- **rack-cors** - CORS for mobile API
- **kaminari** or **pagy** - Pagination
- **sidekiq** - Background jobs (notifications)
- **fcm** - Firebase Cloud Messaging (push notifications)

**Database:** PostgreSQL 15+ (with PostGIS for geospatial queries)

**Hosting Recommendations:**
- Railway.app
- Fly.io
- Render
- Heroku

### Frontend - Expo (React Native)

**Framework:** Expo SDK 50+

**Key Libraries:**
- **expo-router** - File-based routing (App Router)
- **expo-location** - GPS & geolocation
- **expo-notifications** - Push notifications
- **expo-image-picker** - Photo uploads
- **react-native-maps** - Map integration
- **@react-native-async-storage/async-storage** - Local storage
- **axios** - HTTP requests
- **@tanstack/react-query** - Data fetching & caching
- **zustand** - State management
- **react-hook-form** - Form handling
- **zod** - Validation

**Map Provider:** Google Maps API (or Mapbox)

**Export Targets:**
- iOS (App Store)
- Android (Google Play)
- Web (via `expo export:web`)

### Infrastructure

**File Storage:** AWS S3 or Cloudinary (for food photos)

**Push Notifications:** Firebase Cloud Messaging (FCM)

**Background Jobs:** Sidekiq + Redis

**Monitoring:** Sentry (error tracking)

**Analytics:** Mixpanel or PostHog

---

## Database Schema

### Users Table
```ruby
# rails g devise User
# rails g migration AddFieldsToUsers

create_table :users do |t|
  # Devise fields
  t.string :email, null: false, default: ""
  t.string :encrypted_password, null: false, default: ""
  t.string :reset_password_token
  t.datetime :reset_password_sent_at
  t.datetime :remember_created_at

  # Custom fields
  t.string :name, null: false
  t.string :phone
  t.string :role, null: false, default: "consumer" # consumer, marmiteiro, admin
  t.boolean :active, default: true
  t.datetime :last_seen_at

  t.timestamps
end

add_index :users, :email, unique: true
add_index :users, :reset_password_token, unique: true
add_index :users, :role
```

### Marmiteiro Profiles Table
```ruby
create_table :marmiteiro_profiles do |t|
  t.references :user, foreign_key: true, null: false

  # Business info
  t.string :business_name, null: false
  t.text :bio
  t.string :phone
  t.string :whatsapp

  # Location & timing
  t.string :city
  t.string :state
  t.jsonb :operating_hours # { monday: { open: "11:00", close: "14:00" }, ... }

  # Stats
  t.integer :followers_count, default: 0
  t.decimal :average_rating, precision: 3, scale: 2, default: 0.0
  t.integer :reviews_count, default: 0

  # Status
  t.boolean :verified, default: false
  t.boolean :currently_active, default: false # "I'm here!" status
  t.datetime :last_active_at

  t.timestamps
end

add_index :marmiteiro_profiles, :user_id, unique: true
add_index :marmiteiro_profiles, :currently_active
add_index :marmiteiro_profiles, :city
```

### Selling Locations Table
```ruby
create_table :selling_locations do |t|
  t.references :marmiteiro_profile, foreign_key: true, null: false

  t.string :name, null: false # "Praça XV", "Av. Paulista corner"
  t.string :address
  t.decimal :latitude, precision: 10, scale: 6, null: false
  t.decimal :longitude, precision: 10, scale: 6, null: false

  t.boolean :is_regular_spot, default: true
  t.integer :times_used, default: 0

  t.timestamps
end

add_index :selling_locations, [:latitude, :longitude]
add_index :selling_locations, :marmiteiro_profile_id
```

### Weekly Menus Table
```ruby
create_table :daily_menus do |t|
  t.references :marmiteiro_profile, foreign_key: true, null: false
  t.references :selling_location, foreign_key: true # Current location if active

  t.date :menu_date, null: false
  t.string :dish_name, null: false
  t.text :description
  t.decimal :price, precision: 8, scale: 2, null: false

  # Quantity tracking
  t.integer :total_quantity
  t.integer :remaining_quantity

  # Status
  t.boolean :active, default: true
  t.datetime :activated_at
  t.datetime :deactivated_at

  # Categories
  t.string :food_type # traditional, chinese, vegetarian, vegan
  t.jsonb :dietary_tags # ["gluten-free", "dairy-free"]

  t.timestamps
end

add_index :daily_menus, [:marmiteiro_profile_id, :menu_date]
add_index :daily_menus, :menu_date
add_index :daily_menus, :active
```

### Favorites Table
```ruby
create_table :favorites do |t|
  t.references :user, foreign_key: true, null: false
  t.references :marmiteiro_profile, foreign_key: true, null: false

  t.boolean :notifications_enabled, default: true

  t.timestamps
end

add_index :favorites, [:user_id, :marmiteiro_profile_id], unique: true
```

### Reviews Table
```ruby
create_table :reviews do |t|
  t.references :user, foreign_key: true, null: false
  t.references :marmiteiro_profile, foreign_key: true, null: false

  t.integer :rating, null: false # 1-5
  t.text :comment

  t.integer :helpful_count, default: 0

  t.timestamps
end

add_index :reviews, [:user_id, :marmiteiro_profile_id]
add_index :reviews, :marmiteiro_profile_id
add_index :reviews, :rating
```

### Activity Logs Table
```ruby
create_table :activity_logs do |t|
  t.references :marmiteiro_profile, foreign_key: true, null: false
  t.references :selling_location, foreign_key: true

  t.string :activity_type, null: false # "arrived", "departed", "menu_posted", "sold_out"
  t.datetime :occurred_at, null: false
  t.jsonb :metadata # Additional context

  t.timestamps
end

add_index :activity_logs, [:marmiteiro_profile_id, :occurred_at]
add_index :activity_logs, :activity_type
```

### Device Tokens Table (for Push Notifications)
```ruby
create_table :device_tokens do |t|
  t.references :user, foreign_key: true, null: false

  t.string :token, null: false
  t.string :platform # ios, android, web

  t.timestamps
end

add_index :device_tokens, :token, unique: true
add_index :device_tokens, :user_id
```

---

## API Design

### Base URL
```
https://api.marmitas.top/v1
```

### Authentication
**Method:** JWT tokens via Devise

**Headers:**
```
Authorization: Bearer <jwt_token>
```

### Endpoints

#### Authentication

```
POST   /auth/register
POST   /auth/login
POST   /auth/logout
POST   /auth/refresh
GET    /auth/me
PATCH  /auth/profile
```

#### Consumers

```
# Discovery
GET    /marmiteiros                    # List/search marmiteiros
GET    /marmiteiros/:id                # Get marmiteiro details
GET    /marmiteiros/nearby             # Geolocation-based search
GET    /marmiteiros/:id/menu           # Today's menu

# Favorites
GET    /favorites                      # My favorites list
POST   /favorites                      # Add favorite
DELETE /favorites/:id                  # Remove favorite
PATCH  /favorites/:id/notifications    # Toggle notifications

# Reviews
GET    /marmiteiros/:id/reviews        # Get reviews
POST   /marmiteiros/:id/reviews        # Create review
PATCH  /reviews/:id                    # Update review
DELETE /reviews/:id                    # Delete review
POST   /reviews/:id/helpful            # Mark helpful
```

#### Marmiteiros

```
# Profile
GET    /marmiteiro/profile             # My profile
PATCH  /marmiteiro/profile             # Update profile
POST   /marmiteiro/profile/photo       # Upload photo

# Locations
GET    /marmiteiro/locations           # My saved locations
POST   /marmiteiro/locations           # Add location
PATCH  /marmiteiro/locations/:id       # Update location
DELETE /marmiteiro/locations/:id       # Delete location

# Menu
GET    /marmiteiro/menu                # My current menu
POST   /marmiteiro/menu                # Post today's menu
PATCH  /marmiteiro/menu/:id            # Update menu
DELETE /marmiteiro/menu/:id            # Delete menu
GET    /marmiteiro/menu/:id/whatsapp-text  # Get formatted WhatsApp message

# Activity
POST   /marmiteiro/announce-arrival    # "I'm here!"
POST   /marmiteiro/announce-departure  # "I'm leaving!"
PATCH  /marmiteiro/update-quantity     # Update remaining portions

# Stats
GET    /marmiteiro/stats               # Dashboard stats
GET    /marmiteiro/followers           # Follower list
```

#### Admin

```
GET    /admin/users                    # List users
PATCH  /admin/users/:id/verify         # Verify marmiteiro
POST   /admin/users/:id/suspend        # Suspend user
GET    /admin/reports                  # View reports
GET    /admin/stats                    # Platform stats
```

### Real-time Channels (Action Cable)

```
MarmiteirosChannel        # Subscribe to nearby marmiteiros updates
FavoritesChannel          # Subscribe to favorite marmiteiros activity
NotificationsChannel      # Real-time notifications
```

---

## Real-time Features

### WebSocket Events

#### Consumers Subscribe To:

**MarmiteirosChannel (location-based)**
- `marmiteiro.arrived` - A marmiteiro went live nearby
- `marmiteiro.departed` - A marmiteiro left
- `marmiteiro.quantity_updated` - Remaining portions changed

**FavoritesChannel**
- `favorite.arrived` - Your favorite is now active
- `favorite.departed` - Your favorite left
- `favorite.menu_posted` - New menu posted by favorite
- `favorite.announcement` - Custom announcement from favorite

#### Marmiteiros Receive:

**NotificationsChannel**
- `new_follower` - Someone followed you
- `new_review` - Someone reviewed you
- `review_helpful` - Your review was marked helpful

### Push Notifications

**Consumer Notifications:**
1. Favorite goes live
2. Favorite posts new menu
3. Low quantity alert ("Only 3 left!")
4. Custom announcements from favorites

**Marmiteiro Notifications:**
1. New follower
2. New review received
3. Milestone reached (100 followers!)

---

## Mobile App Features

### Consumer App Screens

1. **Map Screen (Home)**
   - Full-screen map with marmiteiro markers
   - Bottom sheet showing selected marmiteiro
   - Filter button (top-right)
   - My location button
   - List/map toggle

2. **Marmiteiro Detail**
   - Hero image
   - Name, rating, follower count
   - Today's menu card (if active)
   - "Follow" button
   - About section
   - Reviews list
   - Regular locations map

3. **Favorites List**
   - List of followed marmiteiros
   - Status indicator (active/inactive)
   - Quick navigation to profile
   - Notification settings per favorite

4. **Search & Filter**
   - Text search
   - Filter by distance, price, food type, rating
   - Sort by distance, rating, newest

5. **Profile (Consumer)**
   - Basic info
   - My reviews
   - Settings
   - Notification preferences

### Marmiteiro App Screens

1. **Dashboard (Home)**
   - Today's stats
   - Quick actions: "Post Menu", "I'm Here!", "I'm Leaving"
   - Current status card
   - Follower count
   - Recent activity

2. **Post Menu**
   - Dish name input
   - Description textarea
   - Price input
   - Quantity input
   - Photo upload (multiple)
   - Food type/dietary tags
   - "Publish" button
   - **After Publishing:**
     - "Copy Menu to Clipboard" button
     - "Share on WhatsApp" button (opens WhatsApp with formatted message)
     - Success toast: "Menu copied! Ready to share on WhatsApp"

3. **Announce Location**
   - Map showing saved locations
   - "Use current location" button
   - "I'm here!" confirms and notifies followers
   - Active session indicator

4. **My Locations**
   - List of saved regular spots
   - Add new location
   - Edit existing
   - Usage count for each

5. **Profile & Stats**
   - Business profile
   - Edit profile
   - View reviews
   - Follower list
   - Weekly/monthly stats

6. **Notifications**
   - New followers
   - New reviews
   - Milestones

### Shared Features

- **Settings:** Notification preferences, account settings, logout
- **Support:** Help, FAQ, contact
- **Onboarding:** Role selection (consumer vs marmiteiro), permissions requests

---

## Security & Privacy

### Authentication & Authorization

**Devise + JWT:**
- Secure password requirements (min 8 chars, complexity)
- JWT tokens with expiration (7 days)
- Refresh token flow
- Email verification (optional but recommended)

**Pundit Policies:**
```ruby
# Example: Only marmiteiros can post menus
class DailyMenuPolicy < ApplicationPolicy
  def create?
    user.marmiteiro?
  end

  def update?
    user.marmiteiro? && record.marmiteiro_profile.user_id == user.id
  end
end
```

### Data Privacy

**Location Data:**
- Consumer location never stored, only used for real-time queries
- Marmiteiro locations only stored when explicitly saved
- Geospatial queries use bounding boxes, not exact coordinates

**User Data:**
- Phone numbers optional
- Personal info never shared without consent
- LGPD compliance (Brazilian data protection law)

**Reviews:**
- Users can only review marmiteiros once
- Reviews can be edited/deleted by author
- Admin moderation for inappropriate content

### Security Best Practices

- HTTPS only
- CORS properly configured
- SQL injection protection (Rails parameterized queries)
- XSS protection (Rails escaping)
- Rate limiting (rack-attack)
- Input validation (strong parameters)
- File upload restrictions (image formats, size limits)

---

## Development Phases

### Phase 1: MVP (8-10 weeks)

**Backend:**
- User authentication (Devise + JWT)
- Basic models: User, MarmiteiroProfile, DailyMenu, Favorite
- Core API endpoints
- PostGIS geospatial queries

**Frontend:**
- Authentication flow
- Map with nearby marmiteiros
- Marmiteiro detail screen
- Post menu flow (marmiteiros)
- Follow/unfollow functionality

**Infrastructure:**
- Rails app deployed (Railway/Render)
- PostgreSQL + Redis
- Basic file storage (ActiveStorage + S3)

**Success Metrics:**
- 10 marmiteiros onboarded
- 50 consumers using app
- 5 weekly menu posts

### Phase 2: Engagement Features (4-6 weeks)

- Push notifications (FCM integration)
- Real-time updates (Action Cable)
- "I'm here!" / "I'm leaving" functionality
- Reviews & ratings
- Photo uploads for menus

**Success Metrics:**
- 50% of users enable notifications
- Average 3 logins per week per user
- 20% of consumers leave reviews

### Phase 3: Growth & Optimization (6-8 weeks)

- Admin panel
- Advanced search & filters
- Saved locations for marmiteiros
- Analytics dashboard (marmiteiros)
- Referral system
- Web export (Expo web)

**Success Metrics:**
- 100 active marmiteiros
- 1000 consumers
- 4.5+ average app rating

### Phase 4: Monetization (Future)

**Potential Revenue Streams:**
- Premium marmiteiro accounts (featured placement, analytics)
- Advertising for food-related businesses
- Transaction fees (if adding in-app payments)
- Subscription for consumers (ad-free, exclusive deals)

---

## Development Setup

### Prerequisites
- Ruby 3.2+
- Rails 8.0+
- PostgreSQL 15+ (with PostGIS)
- Redis 7+
- Node.js 20+ (for Expo)
- Expo CLI

### Backend Setup
```bash
# Clone repo
git clone https://github.com/rafaelbressan/marmitas.top.git
cd marmitas.top/backend

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Run server
rails s
```

### Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Start Expo
npx expo start
```

### Environment Variables
```env
# Backend (.env)
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET_KEY=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET=...
FCM_SERVER_KEY=...
GOOGLE_MAPS_API_KEY=...

# Frontend (.env)
EXPO_PUBLIC_API_URL=https://api.marmitas.top
EXPO_PUBLIC_GOOGLE_MAPS_KEY=...
```

---

## Questions & Decisions Needed

1. **Payment Integration:** Do we want in-app payments, or keep it as discovery-only?
2. **Verification:** How do we verify marmiteiros? Manual review, ID upload, business license?
3. **Delivery:** Future feature? Or strictly "show up and buy" model?
4. **Languages:** Portuguese only, or multi-language?
5. **Moderation:** How strict on food quality/safety? Require health permits?

---

## Next Steps

1. **Repository Setup**
   - Create separate `backend/` and `frontend/` directories
   - Initialize Rails 8 app
   - Initialize Expo app with TypeScript

2. **Database Design**
   - Finalize schema based on feedback
   - Create Rails migrations
   - Set up PostGIS extension

3. **API Development**
   - Implement authentication
   - Build core endpoints
   - Set up testing (RSpec)

4. **Mobile Development**
   - Set up navigation structure
   - Implement map view
   - Build authentication screens

5. **Deployment**
   - Choose hosting provider
   - Set up CI/CD
   - Configure staging environment

---

**Document Status:** Draft v1.0
**Contributors:** Rafael Bressan, Claude
**Next Review:** After stakeholder feedback
