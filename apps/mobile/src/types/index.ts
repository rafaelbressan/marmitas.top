// User & Authentication
export interface User {
  id: number;
  email: string;
  name?: string;
  role: 'consumer' | 'seller';
  created_at: string;
  notification_preferences: NotificationPreferences;
}

export interface NotificationPreferences {
  seller_arrivals: boolean;
  new_menus: boolean;
  order_updates: boolean;
  promotions: boolean;
}

export interface AuthResponse {
  user: User;
  token: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  password_confirmation: string;
  name?: string;
  role: 'consumer' | 'seller';
}

// Seller
export interface SellerLocation {
  id: number;
  name: string;
  address?: string;
  latitude: number;
  longitude: number;
}

export interface SellerProfile {
  id: number;
  business_name: string;
  bio?: string;
  city?: string;
  state?: string;
  verified: boolean;
  currently_active: boolean;
  favorites_count: number;
  is_favorited?: boolean;
  has_current_menu: boolean;
  current_location?: SellerLocation;
  arrived_at?: string;
  leaving_at?: string;
  distance_km?: number;
}

// Map / GeoJSON
export interface GeoJSONFeature {
  type: 'Feature';
  geometry: {
    type: 'Point';
    coordinates: [number, number]; // [longitude, latitude]
  };
  properties: {
    id: number;
    business_name: string;
    bio?: string;
    city?: string;
    state?: string;
    verified: boolean;
    distance_km?: number;
    favorites_count: number;
    is_favorited: boolean;
    has_current_menu: boolean;
    location: {
      id: number;
      name: string;
      address?: string;
    };
    arrived_at?: string;
    leaving_at?: string;
  };
}

export interface GeoJSONFeatureCollection {
  type: 'FeatureCollection';
  features: GeoJSONFeature[];
  metadata: {
    total_sellers: number;
    search_center: {
      latitude: number;
      longitude: number;
    };
    radius_km: number;
  };
}

// Menu & Dishes
export interface Dish {
  id: number;
  name: string;
  description?: string;
  price: number;
  available: boolean;
  favorites_count: number;
  is_favorited?: boolean;
  seller_profile: {
    id: number;
    business_name: string;
  };
}

export interface WeeklyMenu {
  id: number;
  week_start_date: string;
  dishes: Dish[];
  seller_profile: {
    id: number;
    business_name: string;
  };
}

// Favorites
export interface Favorite {
  id: number;
  favoritable_type: 'Dish' | 'SellerProfile';
  favoritable_id: number;
  created_at: string;
}

// Device Token
export interface DeviceToken {
  id: number;
  token: string;
  platform: 'ios' | 'android' | 'web';
  active: boolean;
  last_used_at?: string;
}

// API Response Types
export interface APIError {
  error?: string;
  errors?: string[];
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  per_page: number;
}

// Navigation Types
export type RootStackParamList = {
  Login: undefined;
  Register: undefined;
  Main: undefined;
};

export type MainTabParamList = {
  Home: undefined;
  Map: undefined;
  Favorites: undefined;
  Profile: undefined;
};

export type HomeStackParamList = {
  SellersList: undefined;
  SellerDetail: { sellerId: number };
  MenuDetail: { menuId: number };
};
