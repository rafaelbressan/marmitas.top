# Marmitas.top Backend - Development Guide

## Prerequisites

- Ruby 3.3.6
- Rails 8.1.1
- PostgreSQL 16+
- Redis 7+

## Setup

```bash
# Install dependencies
bundle install

# Create database
bin/rails db:create

# Run migrations (when available)
bin/rails db:migrate

# Seed database (when available)
bin/rails db:seed
```

## Running the Server

```bash
# Start Rails server
bin/rails server

# Or use the dev script
bin/dev
```

The API will be available at `http://localhost:3000`

## Database

- Development: `marmitas_top_development`
- Test: `marmitas_top_test`

## Configuration

CORS is configured to allow:
- localhost:3000 (Rails)
- localhost:8081 (Expo)
- Expo development URLs (exp://...)

## Next Steps

1. Install Devise: `bin/rails generate devise:install`
2. Generate User model: `bin/rails generate devise User`
3. Generate models from RAILS_ARCHITECTURE.md
4. Set up Pundit: `bin/rails g pundit:install`
5. Configure RSpec: `bin/rails generate rspec:install`

## Testing

```bash
# Run tests (when configured)
bundle exec rspec
```

## API Documentation

API will be available at `/api/v1`

See PROJECT_SPECIFICATION_V2.md for full API specification.
