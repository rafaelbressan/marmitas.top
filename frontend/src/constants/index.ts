// API Configuration
export const API_URL = __DEV__
  ? 'http://localhost:3000/api/v1'
  : 'https://api.marmitas.top/api/v1';

// AsyncStorage Keys
export const STORAGE_KEYS = {
  AUTH_TOKEN: '@marmitas:auth_token',
  USER_DATA: '@marmitas:user_data',
  DEVICE_TOKEN: '@marmitas:device_token',
};

// Map Configuration
export const MAP_CONFIG = {
  DEFAULT_LATITUDE: -23.561414, // São Paulo
  DEFAULT_LONGITUDE: -46.655881,
  DEFAULT_RADIUS_KM: 5,
  DEFAULT_ZOOM: 13,
};

// Colors
export const COLORS = {
  primary: '#FF6B35',
  secondary: '#004E89',
  success: '#06D6A0',
  warning: '#FFD23F',
  danger: '#EF476F',
  background: '#F7F7F7',
  card: '#FFFFFF',
  text: '#2E2E2E',
  textLight: '#6E6E6E',
  border: '#E0E0E0',
};

// Dimensions
export const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
};

// Typography
export const FONT_SIZES = {
  xs: 12,
  sm: 14,
  md: 16,
  lg: 18,
  xl: 24,
  xxl: 32,
};

// Notification Types
export const NOTIFICATION_TYPES = {
  SELLER_ARRIVAL: 'seller_arrival',
  NEW_MENU: 'new_menu',
  ORDER_UPDATE: 'order_update',
  PROMOTION: 'promotion',
};
