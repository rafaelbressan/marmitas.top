# Expo Frontend Architecture

**Project:** Marmitas.top Mobile App
**Expo SDK:** 50+
**React Native:** Latest
**TypeScript:** 5.0+

## Table of Contents
- [Directory Structure](#directory-structure)
- [Tech Stack](#tech-stack)
- [Navigation Structure](#navigation-structure)
- [State Management](#state-management)
- [API Integration](#api-integration)
- [Components](#components)
- [Screens](#screens)
- [Hooks](#hooks)
- [Utils](#utils)
- [Testing](#testing)

---

## Directory Structure

```
frontend/
├── app/                              # Expo Router (file-based routing)
│   ├── (auth)/                       # Auth group (stacks)
│   │   ├── login.tsx
│   │   ├── register.tsx
│   │   └── role-selection.tsx
│   │
│   ├── (consumer)/                   # Consumer screens
│   │   ├── _layout.tsx               # Tab navigator
│   │   ├── index.tsx                 # Map screen (home)
│   │   ├── favorites.tsx
│   │   ├── search.tsx
│   │   └── profile.tsx
│   │
│   ├── (marmiteiro)/                 # Marmiteiro screens
│   │   ├── _layout.tsx               # Tab navigator
│   │   ├── dashboard.tsx
│   │   ├── post-menu.tsx
│   │   ├── announce-location.tsx
│   │   ├── my-locations.tsx
│   │   └── business-profile.tsx
│   │
│   ├── (shared)/                     # Shared screens
│   │   ├── marmiteiro-detail/[id].tsx
│   │   ├── notifications.tsx
│   │   └── settings.tsx
│   │
│   ├── _layout.tsx                   # Root layout
│   └── +not-found.tsx
│
├── components/                       # Reusable components
│   ├── ui/                           # UI primitives
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Avatar.tsx
│   │   └── Badge.tsx
│   │
│   ├── map/
│   │   ├── MapView.tsx
│   │   ├── MarmiteiroMarker.tsx
│   │   └── UserLocationMarker.tsx
│   │
│   ├── marmiteiro/
│   │   ├── MarmiteiroCard.tsx
│   │   ├── MarmiteiroList.tsx
│   │   ├── MenuCard.tsx
│   │   └── ReviewCard.tsx
│   │
│   ├── forms/
│   │   ├── MenuForm.tsx
│   │   ├── LocationForm.tsx
│   │   └── ReviewForm.tsx
│   │
│   └── layout/
│       ├── SafeArea.tsx
│       ├── ScreenHeader.tsx
│       └── LoadingSpinner.tsx
│
├── hooks/                            # Custom hooks
│   ├── useAuth.ts
│   ├── useLocation.ts
│   ├── useNotifications.ts
│   ├── useMarmiteiros.ts
│   ├── useWebSocket.ts
│   └── useImagePicker.ts
│
├── services/                         # External services
│   ├── api/
│   │   ├── client.ts                 # Axios instance
│   │   ├── auth.ts
│   │   ├── marmiteiros.ts
│   │   ├── menus.ts
│   │   ├── favorites.ts
│   │   └── reviews.ts
│   │
│   ├── websocket/
│   │   └── socket.ts                 # WebSocket client
│   │
│   ├── storage/
│   │   └── asyncStorage.ts           # Local storage wrapper
│   │
│   └── notifications/
│       └── pushNotifications.ts      # FCM setup
│
├── store/                            # Zustand stores
│   ├── authStore.ts
│   ├── locationStore.ts
│   ├── marmiteirosStore.ts
│   └── notificationsStore.ts
│
├── types/                            # TypeScript types
│   ├── api.types.ts
│   ├── navigation.types.ts
│   └── models.types.ts
│
├── utils/                            # Utility functions
│   ├── validation.ts
│   ├── formatters.ts
│   ├── permissions.ts
│   └── constants.ts
│
├── assets/                           # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── app.json                          # Expo config
├── tsconfig.json
├── package.json
└── README.md
```

---

## Tech Stack

### Core
- **Expo SDK 50+** - React Native framework
- **Expo Router** - File-based routing
- **TypeScript** - Type safety

### UI & Styling
- **NativeWind** - Tailwind CSS for React Native (optional)
- **React Native Paper** - Material Design components (alternative)
- **expo-linear-gradient** - Gradient backgrounds
- **react-native-reanimated** - Animations
- **react-native-gesture-handler** - Gestures

### Navigation
- **expo-router** - File-based routing with tabs/stacks

### Maps & Location
- **react-native-maps** - Map components
- **expo-location** - GPS & geolocation
- **@googlemaps/google-maps-services-js** - Places API (optional)

### State Management
- **zustand** - Lightweight state management
- **@tanstack/react-query** - Server state & caching

### Forms & Validation
- **react-hook-form** - Form handling
- **zod** - Schema validation

### API & Data
- **axios** - HTTP client
- **socket.io-client** - WebSocket (Action Cable)

### Notifications
- **expo-notifications** - Local/push notifications
- **expo-device** - Device info

### Media
- **expo-image-picker** - Photo selection
- **expo-image** - Optimized image component

### Storage
- **@react-native-async-storage/async-storage** - Local storage

### Development
- **@tanstack/eslint-plugin-query** - React Query linting
- **@typescript-eslint** - TypeScript linting
- **prettier** - Code formatting

---

## Navigation Structure

### Root Layout
```typescript
// app/_layout.tsx

import { Stack } from 'expo-router';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from '@/services/api/client';
import { useAuth } from '@/hooks/useAuth';

export default function RootLayout() {
  const { isAuthenticated, user } = useAuth();

  return (
    <QueryClientProvider client={queryClient}>
      <Stack>
        {!isAuthenticated ? (
          <Stack.Screen name="(auth)" options={{ headerShown: false }} />
        ) : user?.role === 'consumer' ? (
          <Stack.Screen name="(consumer)" options={{ headerShown: false }} />
        ) : (
          <Stack.Screen name="(marmiteiro)" options={{ headerShown: false }} />
        )}
      </Stack>
    </QueryClientProvider>
  );
}
```

### Consumer Tabs
```typescript
// app/(consumer)/_layout.tsx

import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function ConsumerLayout() {
  return (
    <Tabs>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Mapa',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="map" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="favorites"
        options={{
          title: 'Favoritos',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="heart" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="search"
        options={{
          title: 'Buscar',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="search" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Perfil',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="person" size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
```

### Marmiteiro Tabs
```typescript
// app/(marmiteiro)/_layout.tsx

import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function MarmiteiroLayout() {
  return (
    <Tabs>
      <Tabs.Screen
        name="dashboard"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="stats-chart" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="post-menu"
        options={{
          title: 'Cardápio',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="restaurant" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="announce-location"
        options={{
          title: 'Localização',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="location" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="business-profile"
        options={{
          title: 'Perfil',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="business" size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
```

---

## State Management

### Auth Store (Zustand)
```typescript
// store/authStore.ts

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@/types/models.types';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: (user, token) =>
        set({ user, token, isAuthenticated: true }),

      logout: () =>
        set({ user: null, token: null, isAuthenticated: false }),

      updateUser: (userData) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...userData } : null,
        })),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

### Location Store
```typescript
// store/locationStore.ts

import { create } from 'zustand';
import { LocationObject } from 'expo-location';

interface LocationState {
  userLocation: LocationObject | null;
  mapRegion: {
    latitude: number;
    longitude: number;
    latitudeDelta: number;
    longitudeDelta: number;
  } | null;
  setUserLocation: (location: LocationObject) => void;
  setMapRegion: (region: LocationState['mapRegion']) => void;
}

export const useLocationStore = create<LocationState>((set) => ({
  userLocation: null,
  mapRegion: null,

  setUserLocation: (location) => set({ userLocation: location }),

  setMapRegion: (region) => set({ mapRegion: region }),
}));
```

---

## API Integration

### API Client Setup
```typescript
// services/api/client.ts

import axios from 'axios';
import { useAuthStore } from '@/store/authStore';
import { QueryClient } from '@tanstack/react-query';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

export const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add JWT token
apiClient.interceptors.request.use(
  (config) => {
    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
    }
    return Promise.reject(error);
  }
);

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});
```

### Auth API Service
```typescript
// services/api/auth.ts

import { apiClient } from './client';
import { User } from '@/types/models.types';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  role: 'consumer' | 'marmiteiro';
}

export const authApi = {
  login: async (credentials: LoginCredentials) => {
    const { data } = await apiClient.post<{ user: User; token: string }>(
      '/auth/login',
      credentials
    );
    return data;
  },

  register: async (userData: RegisterData) => {
    const { data } = await apiClient.post<{ user: User; token: string }>(
      '/auth/register',
      userData
    );
    return data;
  },

  logout: async () => {
    await apiClient.post('/auth/logout');
  },

  me: async () => {
    const { data } = await apiClient.get<{ user: User }>('/auth/me');
    return data.user;
  },
};
```

### Marmiteiros API Service
```typescript
// services/api/marmiteiros.ts

import { apiClient } from './client';
import { MarmiteiroProfile, DailyMenu } from '@/types/models.types';

export const marmiteirosApi = {
  getNearby: async (latitude: number, longitude: number, radius: number = 5) => {
    const { data } = await apiClient.get<{ data: MarmiteiroProfile[] }>(
      '/marmiteiros/nearby',
      { params: { latitude, longitude, radius } }
    );
    return data.data;
  },

  getById: async (id: number) => {
    const { data } = await apiClient.get<{ data: MarmiteiroProfile }>(
      `/marmiteiros/${id}`
    );
    return data.data;
  },

  getMenu: async (id: number) => {
    const { data } = await apiClient.get<{ data: DailyMenu }>(
      `/marmiteiros/${id}/menu`
    );
    return data.data;
  },

  search: async (query: string, filters?: Record<string, any>) => {
    const { data } = await apiClient.get<{ data: MarmiteiroProfile[] }>(
      '/marmiteiros',
      { params: { q: query, ...filters } }
    );
    return data.data;
  },
};
```

---

## Hooks

### useAuth Hook
```typescript
// hooks/useAuth.ts

import { useMutation } from '@tanstack/react-query';
import { useAuthStore } from '@/store/authStore';
import { authApi, LoginCredentials, RegisterData } from '@/services/api/auth';
import { useRouter } from 'expo-router';

export const useAuth = () => {
  const router = useRouter();
  const { user, token, isAuthenticated, login: setAuth, logout: clearAuth } = useAuthStore();

  const loginMutation = useMutation({
    mutationFn: (credentials: LoginCredentials) => authApi.login(credentials),
    onSuccess: (data) => {
      setAuth(data.user, data.token);
      router.replace(data.user.role === 'consumer' ? '/(consumer)' : '/(marmiteiro)');
    },
  });

  const registerMutation = useMutation({
    mutationFn: (userData: RegisterData) => authApi.register(userData),
    onSuccess: (data) => {
      setAuth(data.user, data.token);
      router.replace(data.user.role === 'consumer' ? '/(consumer)' : '/(marmiteiro)');
    },
  });

  const logout = async () => {
    await authApi.logout();
    clearAuth();
    router.replace('/(auth)/login');
  };

  return {
    user,
    token,
    isAuthenticated,
    login: loginMutation.mutate,
    register: registerMutation.mutate,
    logout,
    isLoggingIn: loginMutation.isPending,
    isRegistering: registerMutation.isPending,
  };
};
```

### useLocation Hook
```typescript
// hooks/useLocation.ts

import { useState, useEffect } from 'react';
import * as Location from 'expo-location';
import { useLocationStore } from '@/store/locationStore';

export const useLocation = () => {
  const { userLocation, setUserLocation } = useLocationStore();
  const [permissionStatus, setPermissionStatus] = useState<Location.PermissionStatus | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      setPermissionStatus(status);

      if (status === 'granted') {
        const location = await Location.getCurrentPositionAsync({});
        setUserLocation(location);
      }
      setIsLoading(false);
    })();
  }, []);

  const refreshLocation = async () => {
    if (permissionStatus === 'granted') {
      const location = await Location.getCurrentPositionAsync({});
      setUserLocation(location);
    }
  };

  return {
    userLocation,
    permissionStatus,
    isLoading,
    refreshLocation,
    hasPermission: permissionStatus === 'granted',
  };
};
```

### useMarmiteiros Hook
```typescript
// hooks/useMarmiteiros.ts

import { useQuery } from '@tanstack/react-query';
import { marmiteirosApi } from '@/services/api/marmiteiros';
import { useLocation } from './useLocation';

export const useMarmiteiros = (radius: number = 5) => {
  const { userLocation } = useLocation();

  return useQuery({
    queryKey: ['marmiteiros', 'nearby', userLocation?.coords.latitude, userLocation?.coords.longitude, radius],
    queryFn: () => {
      if (!userLocation) throw new Error('Location not available');
      return marmiteirosApi.getNearby(
        userLocation.coords.latitude,
        userLocation.coords.longitude,
        radius
      );
    },
    enabled: !!userLocation,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
};

export const useMarmiteiroDetail = (id: number) => {
  return useQuery({
    queryKey: ['marmiteiro', id],
    queryFn: () => marmiteirosApi.getById(id),
  });
};
```

---

## Screens

### Consumer Map Screen
```typescript
// app/(consumer)/index.tsx

import { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import MapView, { Marker, PROVIDER_GOOGLE } from 'react-native-maps';
import { useMarmiteiros } from '@/hooks/useMarmiteiros';
import { useLocation } from '@/hooks/useLocation';
import { MarmiteiroMarker } from '@/components/map/MarmiteiroMarker';
import { MarmiteiroBottomSheet } from '@/components/map/MarmiteiroBottomSheet';
import { LoadingSpinner } from '@/components/layout/LoadingSpinner';

export default function MapScreen() {
  const { userLocation } = useLocation();
  const { data: marmiteiros, isLoading } = useMarmiteiros(10);
  const [selectedMarmiteiro, setSelectedMarmiteiro] = useState(null);

  if (isLoading || !userLocation) {
    return <LoadingSpinner />;
  }

  return (
    <View style={styles.container}>
      <MapView
        provider={PROVIDER_GOOGLE}
        style={styles.map}
        initialRegion={{
          latitude: userLocation.coords.latitude,
          longitude: userLocation.coords.longitude,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        }}
        showsUserLocation
        showsMyLocationButton
      >
        {marmiteiros?.map((marmiteiro) => (
          <MarmiteiroMarker
            key={marmiteiro.id}
            marmiteiro={marmiteiro}
            onPress={() => setSelectedMarmiteiro(marmiteiro)}
          />
        ))}
      </MapView>

      {selectedMarmiteiro && (
        <MarmiteiroBottomSheet
          marmiteiro={selectedMarmiteiro}
          onClose={() => setSelectedMarmiteiro(null)}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { flex: 1 },
});
```

### Marmiteiro Dashboard
```typescript
// app/(marmiteiro)/dashboard.tsx

import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { useRouter } from 'expo-router';

export default function DashboardScreen() {
  const router = useRouter();

  const { data: stats } = useQuery({
    queryKey: ['marmiteiro', 'stats'],
    queryFn: async () => {
      // Fetch stats from API
      return { followers: 42, views: 128, rating: 4.5 };
    },
  });

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Dashboard</Text>

      {/* Stats Cards */}
      <View style={styles.statsRow}>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{stats?.followers}</Text>
          <Text style={styles.statLabel}>Seguidores</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{stats?.views}</Text>
          <Text style={styles.statLabel}>Visualizações</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{stats?.rating}</Text>
          <Text style={styles.statLabel}>Avaliação</Text>
        </Card>
      </View>

      {/* Quick Actions */}
      <View style={styles.actions}>
        <Button
          title="Postar Cardápio"
          onPress={() => router.push('/(marmiteiro)/post-menu')}
          style={styles.actionButton}
        />
        <Button
          title="Anunciar Chegada"
          onPress={() => router.push('/(marmiteiro)/announce-location')}
          variant="secondary"
          style={styles.actionButton}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 16 },
  statsRow: { flexDirection: 'row', gap: 12 },
  statCard: { flex: 1, padding: 16 },
  statValue: { fontSize: 32, fontWeight: 'bold' },
  statLabel: { fontSize: 14, color: '#666' },
  actions: { marginTop: 24, gap: 12 },
  actionButton: { marginBottom: 8 },
});
```

---

## Components

### Marmiteiro Card
```typescript
// components/marmiteiro/MarmiteiroCard.tsx

import { View, Text, Image, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { MarmiteiroProfile } from '@/types/models.types';

interface Props {
  marmiteiro: MarmiteiroProfile;
  onPress: () => void;
}

export const MarmiteiroCard = ({ marmiteiro, onPress }: Props) => {
  return (
    <Pressable style={styles.card} onPress={onPress}>
      <Image
        source={{ uri: marmiteiro.profile_photo_url }}
        style={styles.image}
      />
      <View style={styles.content}>
        <Text style={styles.name}>{marmiteiro.business_name}</Text>
        <View style={styles.rating}>
          <Ionicons name="star" size={16} color="#FFD700" />
          <Text style={styles.ratingText}>
            {marmiteiro.average_rating.toFixed(1)} ({marmiteiro.reviews_count})
          </Text>
        </View>
        {marmiteiro.currently_active && (
          <View style={styles.activeBadge}>
            <Text style={styles.activeText}>🟢 Ativo agora</Text>
          </View>
        )}
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  image: { width: 80, height: 80, borderRadius: 8 },
  content: { flex: 1, marginLeft: 12 },
  name: { fontSize: 18, fontWeight: 'bold' },
  rating: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  ratingText: { marginLeft: 4, color: '#666' },
  activeBadge: { marginTop: 8 },
  activeText: { fontSize: 12, color: '#22c55e', fontWeight: '600' },
});
```

---

## Testing

### Unit Test Example
```typescript
// hooks/__tests__/useAuth.test.ts

import { renderHook, act } from '@testing-library/react-hooks';
import { useAuth } from '../useAuth';

describe('useAuth', () => {
  it('should login successfully', async () => {
    const { result } = renderHook(() => useAuth());

    await act(async () => {
      result.current.login({ email: 'test@test.com', password: 'password' });
    });

    expect(result.current.isAuthenticated).toBe(true);
  });
});
```

---

## Next Steps

1. **Initialize Expo Project**
   ```bash
   npx create-expo-app frontend --template tabs
   cd frontend
   ```

2. **Install Dependencies**
   ```bash
   npx expo install expo-router expo-location expo-notifications react-native-maps
   npm install axios @tanstack/react-query zustand zod react-hook-form
   ```

3. **Configure Environment**
   ```bash
   # .env
   EXPO_PUBLIC_API_URL=http://localhost:3000/api/v1
   EXPO_PUBLIC_GOOGLE_MAPS_KEY=your_key_here
   ```

4. **Set Up TypeScript**
   Already configured with Expo

5. **Run Development Server**
   ```bash
   npx expo start
   ```

---

**Document Version:** 1.0
**Last Updated:** November 7, 2025
