# Marmitas.top - Frontend Mobile App

React Native mobile application built with Expo for the Marmitas.top food marketplace platform.

## Technology Stack

- **React Native** with **Expo SDK 54**
- **TypeScript** for type safety
- **React Navigation** for routing (Stack + Bottom Tabs)
- **React Native Maps** for geospatial features
- **Axios** for API communication
- **AsyncStorage** for local data persistence
- **Expo Location** for geolocation
- **Expo Notifications** for push notifications

## Features Implemented

### Authentication
- ✅ Login screen with email/password
- ✅ Registration screen with role selection (Consumer/Seller)
- ✅ JWT token management with AsyncStorage
- ✅ Auth context with automatic token refresh
- ✅ Protected routes based on authentication state

### Core Features
- ✅ **Map View**: Interactive map showing nearby active sellers using PostGIS geospatial data
- ✅ **Home Screen**: List of nearby sellers with distance calculation and sorting
- ✅ **Seller Detail**: Detailed seller information with menus and location
- ✅ **Favorites**: Save favorite sellers and dishes with visual indicators
- ✅ **Profile**: User profile management and logout

### API Integration
All backend endpoints are integrated:
- Auth endpoints (login, register, logout, me)
- Sellers endpoints (list, nearby search, detail)
- Map endpoints (GeoJSON sellers, bounds)
- Menus endpoints (list, available today, seller menus)
- Favorites endpoints (CRUD operations for dishes and sellers)
- Device tokens (for push notifications)
- Notification preferences

### UI/UX Features
- Pull-to-refresh on all list screens
- Loading states with activity indicators
- Empty states with helpful messages
- Error handling with user-friendly alerts
- Real-time location updates
- Distance calculation and display
- Favorited sellers appear first in listings
- Visual indicators for active/inactive sellers
- Verified badges for trusted sellers

## Project Structure

```
frontend/
├── src/
│   ├── screens/           # All screen components
│   │   ├── LoginScreen.tsx
│   │   ├── RegisterScreen.tsx
│   │   ├── HomeScreen.tsx
│   │   ├── MapScreen.tsx
│   │   ├── SellerDetailScreen.tsx
│   │   ├── FavoritesScreen.tsx
│   │   └── ProfileScreen.tsx
│   ├── navigation/        # Navigation setup
│   │   └── AppNavigator.tsx
│   ├── contexts/          # React contexts
│   │   └── AuthContext.tsx
│   ├── services/          # API service layer
│   │   └── api.ts
│   ├── types/             # TypeScript type definitions
│   │   └── index.ts
│   ├── constants/         # App constants (colors, API URL, etc.)
│   │   └── index.ts
│   ├── components/        # Reusable components (empty for now)
│   └── utils/             # Utility functions (empty for now)
├── App.tsx                # Root component
├── package.json
└── tsconfig.json
```

## Setup & Installation

1. **Install dependencies**:
   ```bash
   cd frontend
   npm install
   ```

2. **Configure API URL**:
   The API URL is configured in `src/constants/index.ts`:
   - Development: `http://localhost:3000/api/v1`
   - Production: `https://api.marmitas.top/api/v1`

3. **Run the app**:
   ```bash
   # Start Expo dev server
   npm start

   # Run on iOS simulator
   npm run ios

   # Run on Android emulator
   npm run android

   # Run on web
   npm run web
   ```

## Backend Integration

The frontend communicates with the Rails API backend. Make sure the backend is running:

```bash
cd backend
rails server
```

The API service (`src/services/api.ts`) automatically:
- Adds JWT token to all requests
- Handles token expiration (401 errors)
- Stores/retrieves tokens from AsyncStorage
- Provides type-safe API methods

## Testing User Flow

### As a Consumer:
1. Register with role "Consumer"
2. Grant location permissions
3. View nearby sellers on Home or Map
4. Click on a seller to see details and menus
5. Favorite sellers/dishes (they'll appear first in lists)
6. Check Favorites tab for saved items
7. View profile and manage settings

### As a Seller:
1. Register with role "Seller"
2. Set up seller profile in backend
3. Create selling locations
4. Broadcast arrival/departure
5. Manage menus and dishes
6. View which dishes are most favorited

## Map Integration

The map view uses:
- **react-native-maps** for rendering
- **expo-location** for user's current location
- **PostGIS GeoJSON API** for seller markers
- Real-time marker updates based on map region
- Color-coded pins (yellow star for favorited sellers)

## Next Steps

### High Priority
- [ ] Push notification setup (FCM registration)
- [ ] Orders & Purchases system
- [ ] Reviews & Ratings UI
- [ ] Menu browsing improvements
- [ ] Search & filters

### Medium Priority
- [ ] Image upload for dishes/sellers
- [ ] WhatsApp sharing integration
- [ ] Offline support
- [ ] Performance optimization
- [ ] Analytics tracking

### UI Improvements
- [ ] Custom icons instead of emojis
- [ ] Better map markers
- [ ] Image carousels for dishes
- [ ] Skeleton loaders
- [ ] Animations and transitions

## Environment Variables

For production, configure:
- `API_URL` - Backend API endpoint
- `FCM_SERVER_KEY` - Firebase Cloud Messaging key (for notifications)

## Troubleshooting

### Common Issues

1. **Cannot connect to API**:
   - Make sure backend is running on `http://localhost:3000`
   - Check API_URL in constants
   - For iOS simulator, use localhost
   - For Android emulator, use 10.0.2.2 instead of localhost

2. **Location not working**:
   - Grant location permissions when prompted
   - On simulators, set custom location in device settings

3. **Maps not showing**:
   - Ensure you have internet connection
   - Check API key configuration (if using Google Maps)
   - Verify backend is returning GeoJSON data

4. **TypeScript errors**:
   - Run `npm install` to ensure all types are installed
   - Check that `@types/react` and other type packages are installed

## Contributing

When adding new features:
1. Add types to `src/types/index.ts`
2. Add API methods to `src/services/api.ts`
3. Create screens in `src/screens/`
4. Update navigation in `src/navigation/AppNavigator.tsx`
5. Update this README with changes

## License

Proprietary - © 2025 Marmitas.top
