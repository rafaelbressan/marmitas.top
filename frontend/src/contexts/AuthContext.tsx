import React, { createContext, useState, useContext, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '../constants';
import { api } from '../services/api';
import type { User, LoginCredentials, RegisterData } from '../types';

interface AuthContextData {
  user: User | null;
  loading: boolean;
  signIn: (credentials: LoginCredentials) => Promise<void>;
  signUp: (userData: RegisterData) => Promise<void>;
  signOut: () => Promise<void>;
  refreshUser: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextData>({} as AuthContextData);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStoredData();
  }, []);

  async function loadStoredData() {
    try {
      const [token, storedUser] = await AsyncStorage.multiGet([
        STORAGE_KEYS.AUTH_TOKEN,
        STORAGE_KEYS.USER_DATA,
      ]);

      if (token[1] && storedUser[1]) {
        setUser(JSON.parse(storedUser[1]));
        // Optionally refresh user data from server
        try {
          const userData = await api.getCurrentUser();
          setUser(userData);
        } catch (error) {
          console.error('Error refreshing user data:', error);
        }
      }
    } catch (error) {
      console.error('Error loading stored data:', error);
    } finally {
      setLoading(false);
    }
  }

  async function signIn(credentials: LoginCredentials) {
    try {
      const response = await api.login(credentials);
      setUser(response.user);
    } catch (error) {
      throw error;
    }
  }

  async function signUp(userData: RegisterData) {
    try {
      const response = await api.register(userData);
      setUser(response.user);
    } catch (error) {
      throw error;
    }
  }

  async function signOut() {
    try {
      await api.logout();
    } catch (error) {
      console.error('Error during logout:', error);
    } finally {
      setUser(null);
    }
  }

  async function refreshUser() {
    try {
      const userData = await api.getCurrentUser();
      setUser(userData);
    } catch (error) {
      console.error('Error refreshing user:', error);
      throw error;
    }
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        signIn,
        signUp,
        signOut,
        refreshUser,
        isAuthenticated: !!user,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
