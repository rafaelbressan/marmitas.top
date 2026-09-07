import axios, { AxiosInstance, AxiosError } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_URL, STORAGE_KEYS } from '../constants';
import type {
  User,
  AuthResponse,
  LoginCredentials,
  RegisterData,
  SellerProfile,
  GeoJSONFeatureCollection,
  Dish,
  WeeklyMenu,
  Favorite,
  DeviceToken,
  NotificationPreferences,
  APIError,
} from '../types';

class APIService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: API_URL,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    });

    // Request interceptor to add auth token
    this.api.interceptors.request.use(
      async (config) => {
        const token = await AsyncStorage.getItem(STORAGE_KEYS.AUTH_TOKEN);
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.api.interceptors.response.use(
      (response) => response,
      async (error: AxiosError<APIError>) => {
        if (error.response?.status === 401) {
          // Token expired or invalid, clear storage
          await AsyncStorage.multiRemove([
            STORAGE_KEYS.AUTH_TOKEN,
            STORAGE_KEYS.USER_DATA,
          ]);
        }
        return Promise.reject(error);
      }
    );
  }

  // Auth endpoints
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const { data } = await this.api.post<AuthResponse>('/auth/login', credentials);
    await AsyncStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, data.token);
    await AsyncStorage.setItem(STORAGE_KEYS.USER_DATA, JSON.stringify(data.user));
    return data;
  }

  async register(userData: RegisterData): Promise<AuthResponse> {
    const { data } = await this.api.post<AuthResponse>('/auth/register', userData);
    await AsyncStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, data.token);
    await AsyncStorage.setItem(STORAGE_KEYS.USER_DATA, JSON.stringify(data.user));
    return data;
  }

  async logout(): Promise<void> {
    try {
      await this.api.delete('/auth/logout');
    } finally {
      await AsyncStorage.multiRemove([
        STORAGE_KEYS.AUTH_TOKEN,
        STORAGE_KEYS.USER_DATA,
      ]);
    }
  }

  async getCurrentUser(): Promise<User> {
    const { data } = await this.api.get<{ user: User }>('/auth/me');
    await AsyncStorage.setItem(STORAGE_KEYS.USER_DATA, JSON.stringify(data.user));
    return data.user;
  }

  // Sellers endpoints
  async getSellers(params?: { page?: number; per_page?: number }): Promise<{ sellers: SellerProfile[] }> {
    const { data } = await this.api.get<{ sellers: SellerProfile[] }>('/sellers', { params });
    return data;
  }

  async getNearbySellers(
    latitude: number,
    longitude: number,
    radius?: number
  ): Promise<{ sellers: SellerProfile[]; search_params: any }> {
    const { data } = await this.api.get<{ sellers: SellerProfile[]; search_params: any }>(
      '/sellers/nearby',
      {
        params: { latitude, longitude, radius },
      }
    );
    return data;
  }

  async getSeller(id: number): Promise<{ seller: SellerProfile }> {
    const { data } = await this.api.get<{ seller: SellerProfile }>(`/sellers/${id}`);
    return data;
  }

  // Map endpoints
  async getMapSellers(
    latitude: number,
    longitude: number,
    radius?: number
  ): Promise<GeoJSONFeatureCollection> {
    const { data } = await this.api.get<GeoJSONFeatureCollection>('/map/sellers', {
      params: { latitude, longitude, radius },
    });
    return data;
  }

  async getMapBounds(
    ne_lat: number,
    ne_lng: number,
    sw_lat: number,
    sw_lng: number
  ): Promise<GeoJSONFeatureCollection> {
    const { data } = await this.api.get<GeoJSONFeatureCollection>('/map/bounds', {
      params: { ne_lat, ne_lng, sw_lat, sw_lng },
    });
    return data;
  }

  // Menus endpoints
  async getMenus(params?: { page?: number; per_page?: number }): Promise<{ menus: WeeklyMenu[] }> {
    const { data } = await this.api.get<{ menus: WeeklyMenu[] }>('/menus', { params });
    return data;
  }

  async getAvailableMenusToday(): Promise<{ menus: WeeklyMenu[] }> {
    const { data } = await this.api.get<{ menus: WeeklyMenu[] }>('/menus/available_today');
    return data;
  }

  async getSellerMenus(sellerId: number): Promise<{ menus: WeeklyMenu[] }> {
    const { data } = await this.api.get<{ menus: WeeklyMenu[] }>(`/sellers/${sellerId}/menus`);
    return data;
  }

  // Favorites endpoints
  async getFavorites(): Promise<{
    favorites: Favorite[];
    dishes: Dish[];
    sellers: SellerProfile[];
  }> {
    const { data } = await this.api.get<{
      favorites: Favorite[];
      dishes: Dish[];
      sellers: SellerProfile[];
    }>('/favorites');
    return data;
  }

  async getFavoriteDishes(): Promise<{ dishes: Dish[] }> {
    const { data } = await this.api.get<{ dishes: Dish[] }>('/favorites/dishes');
    return data;
  }

  async getFavoriteSellers(): Promise<{ sellers: SellerProfile[] }> {
    const { data } = await this.api.get<{ sellers: SellerProfile[] }>('/favorites/sellers');
    return data;
  }

  async addFavorite(
    favoritableType: 'Dish' | 'SellerProfile',
    favoritableId: number
  ): Promise<{ message: string; favorite: Favorite }> {
    const { data } = await this.api.post<{ message: string; favorite: Favorite }>(
      '/favorites',
      {
        favoritable_type: favoritableType,
        favoritable_id: favoritableId,
      }
    );
    return data;
  }

  async removeFavorite(favoritableType: 'Dish' | 'SellerProfile', favoritableId: number): Promise<void> {
    await this.api.delete('/favorites/remove', {
      params: {
        favoritable_type: favoritableType,
        favoritable_id: favoritableId,
      },
    });
  }

  async checkFavorite(
    favoritableType: 'Dish' | 'SellerProfile',
    favoritableId: number
  ): Promise<{ is_favorited: boolean }> {
    const { data } = await this.api.get<{ is_favorited: boolean }>('/favorites/check', {
      params: {
        favoritable_type: favoritableType,
        favoritable_id: favoritableId,
      },
    });
    return data;
  }

  // Device Tokens (for push notifications)
  async registerDeviceToken(
    token: string,
    platform: 'ios' | 'android' | 'web'
  ): Promise<{ device_token: DeviceToken }> {
    const { data } = await this.api.post<{ device_token: DeviceToken }>(
      '/device_tokens',
      { token, platform }
    );
    await AsyncStorage.setItem(STORAGE_KEYS.DEVICE_TOKEN, token);
    return data;
  }

  async getDeviceTokens(): Promise<{ device_tokens: DeviceToken[] }> {
    const { data } = await this.api.get<{ device_tokens: DeviceToken[] }>('/device_tokens');
    return data;
  }

  async deleteDeviceToken(id: number): Promise<void> {
    await this.api.delete(`/device_tokens/${id}`);
  }

  async deactivateAllDeviceTokens(): Promise<void> {
    await this.api.post('/device_tokens/deactivate_all');
  }

  // Notification Preferences
  async getNotificationPreferences(): Promise<{ notification_preferences: NotificationPreferences }> {
    const { data } = await this.api.get<{ notification_preferences: NotificationPreferences }>(
      '/notification_preferences'
    );
    return data;
  }

  async updateNotificationPreferences(
    preferences: Partial<NotificationPreferences>
  ): Promise<{ message: string; notification_preferences: NotificationPreferences }> {
    const { data } = await this.api.patch<{
      message: string;
      notification_preferences: NotificationPreferences;
    }>('/notification_preferences', { notification_preferences: preferences });
    return data;
  }
}

export const api = new APIService();
export default api;
