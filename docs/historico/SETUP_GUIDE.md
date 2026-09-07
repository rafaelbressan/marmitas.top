# Marmitas.top V2 - Setup Guide

**Version:** 2.0
**Last Updated:** November 7, 2025
**Status:** Initial Setup Complete ✅

## Project Structure

```
marmitas.top/
├── backend/                   # Rails 8 API
│   ├── app/
│   ├── config/
│   ├── db/
│   ├── Gemfile
│   └── DEVELOPMENT.md        # Backend setup guide
│
├── frontend/                  # Expo React Native App (Coming soon)
│   ├── app/
│   ├── assets/
│   ├── package.json
│   └── README.md
│
├── PROJECT_SPECIFICATION_V2.md
├── RAILS_ARCHITECTURE.md
├── EXPO_ARCHITECTURE.md
├── REPOSITORY_ANALYSIS.md
└── SETUP_GUIDE.md (this file)
```

## Quick Start

### Prerequisites Installed ✅

- ✅ Ruby 3.3.6
- ✅ Rails 8.1.1
- ✅ Node.js 22.21.1
- ✅ PostgreSQL 16.10
- ✅ Redis 7.0.15

### Backend Setup (Completed)

```bash
cd backend

# Dependencies are installed ✅
# Database created ✅
# CORS configured ✅

# Start the server
bin/rails server
# API available at http://localhost:3000
```

### Frontend Setup (Initialized)

```bash
cd frontend

# Install dependencies (already done)
npm install

# Start Expo
npx expo start

# Or run on specific platform
npm run android   # Android
npm run ios       # iOS (macOS only)
npm run web       # Web browser
```

## What's Been Done

### ✅ Backend (Rails 8)
- [x] Rails 8 API application created
- [x] PostgreSQL databases created (`marmitas_top_development`, `marmitas_top_test`)
- [x] Essential gems installed:
  - devise, devise-jwt (authentication)
  - pundit (authorization)
  - geocoder (geolocation)
  - sidekiq, redis (background jobs)
  - rack-cors (CORS)
  - rspec-rails, factory_bot_rails (testing)
- [x] CORS configured for Expo development
- [x] Database configuration updated

### ✅ Frontend (Expo)
- [x] Expo TypeScript project initialized
- [x] Node dependencies installed
- [x] Ready for development

### ✅ Documentation
- [x] Complete product specification
- [x] Rails architecture design
- [x] Expo architecture design
- [x] Database schema design
- [x] API endpoints specification

## Next Development Steps

### Phase 1: Core Authentication (Week 1)

#### Backend
```bash
cd backend

# 1. Install Devise
bin/rails generate devise:install
bin/rails generate devise User
bin/rails db:migrate

# 2. Add custom fields to User
bin/rails generate migration AddFieldsToUsers name:string phone:string role:string
bin/rails db:migrate

# 3. Configure Devise JWT
# Follow backend/config/initializers/devise.rb

# 4. Set up Pundit
bin/rails g pundit:install

# 5. Create API controllers
mkdir -p app/controllers/api/v1
# Create auth_controller.rb, marmiteiros_controller.rb
```

#### Frontend
```bash
cd frontend

# 1. Install dependencies
npm install axios @tanstack/react-query zustand expo-router
npm install react-native-maps expo-location expo-notifications

# 2. Set up directory structure
mkdir -p app/(auth) app/(consumer) app/(marmiteiro)
mkdir -p components/ui components/map
mkdir -p services/api store hooks

# 3. Create API client
# services/api/client.ts

# 4. Set up auth store
# store/authStore.ts
```

### Phase 2: Core Models (Week 2)

```bash
cd backend

# Generate models based on RAILS_ARCHITECTURE.md
bin/rails g model MarmiteiroProfile user:references business_name:string bio:text
bin/rails g model SellingLocation marmiteiro_profile:references name:string latitude:decimal longitude:decimal
bin/rails g model DailyMenu marmiteiro_profile:references dish_name:string price:decimal
bin/rails g model Favorite user:references marmiteiro_profile:references
bin/rails g model Review user:references marmiteiro_profile:references rating:integer comment:text

bin/rails db:migrate
```

### Phase 3: Map & Location (Week 3)

- Implement map view with markers
- Nearby marmiteiros search
- Location permissions
- Real-time updates via Action Cable

### Phase 4: Push Notifications (Week 4)

- Firebase FCM setup
- Notification service
- Device token management
- "I'm here!" announcements

## Environment Variables

### Backend (.env)
```bash
# Create backend/.env
DATABASE_URL=postgresql://localhost/marmitas_top_development
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=generate_with_rails_secret
```

### Frontend (.env)
```bash
# Create frontend/.env
EXPO_PUBLIC_API_URL=http://localhost:3000/api/v1
```

## Running the Full Stack

### Terminal 1: Backend
```bash
cd backend
bin/rails server
```

### Terminal 2: Redis (for Sidekiq)
```bash
redis-server
```

### Terminal 3: Sidekiq (when needed)
```bash
cd backend
bundle exec sidekiq
```

### Terminal 4: Frontend
```bash
cd frontend
npx expo start
```

## Testing

### Backend Tests
```bash
cd backend
bundle exec rspec
```

### Frontend (When configured)
```bash
cd frontend
npm test
```

## Deployment (Future)

- **Backend:** Railway.app, Fly.io, or Render
- **Frontend:** Expo Application Services (EAS)
- **Database:** Managed PostgreSQL
- **File Storage:** Cloudinary or AWS S3

## Documentation Reference

- **Product Spec:** `PROJECT_SPECIFICATION_V2.md`
- **Backend Architecture:** `RAILS_ARCHITECTURE.md`
- **Frontend Architecture:** `EXPO_ARCHITECTURE.md`
- **Backend Dev Guide:** `backend/DEVELOPMENT.md`

## Troubleshooting

### PostgreSQL Issues
```bash
# Check if PostgreSQL is running
pg_isready

# Restart PostgreSQL
service postgresql restart
```

### Redis Issues
```bash
# Check if Redis is running
redis-cli ping

# Start Redis
redis-server --daemonize yes
```

### Expo Issues
```bash
# Clear Expo cache
npx expo start --clear
```

## Support

For questions or issues, refer to:
- Rails Guides: https://guides.rubyonrails.org
- Expo Documentation: https://docs.expo.dev
- Project specifications in this repository

---

**Ready to start coding!** 🚀

Next: Follow Phase 1 steps above to implement authentication.
