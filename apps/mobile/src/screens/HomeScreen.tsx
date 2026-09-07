import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
  Alert,
} from 'react-native';
import * as Location from 'expo-location';
import { api } from '../services/api';
import { COLORS, SPACING, FONT_SIZES, MAP_CONFIG } from '../constants';
import type { SellerProfile } from '../types';
import type { CompositeNavigationProp } from '@react-navigation/native';
import type { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { MainTabParamList, HomeStackParamList } from '../types';

type HomeScreenNavigationProp = CompositeNavigationProp<
  BottomTabNavigationProp<MainTabParamList, 'Home'>,
  StackNavigationProp<HomeStackParamList>
>;

interface Props {
  navigation: HomeScreenNavigationProp;
}

export const HomeScreen: React.FC<Props> = ({ navigation }) => {
  const [sellers, setSellers] = useState<SellerProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [location, setLocation] = useState<{ latitude: number; longitude: number } | null>(
    null
  );

  useEffect(() => {
    loadLocation();
  }, []);

  const loadLocation = async () => {
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        // Use default location
        setLocation({
          latitude: MAP_CONFIG.DEFAULT_LATITUDE,
          longitude: MAP_CONFIG.DEFAULT_LONGITUDE,
        });
        await fetchSellers(MAP_CONFIG.DEFAULT_LATITUDE, MAP_CONFIG.DEFAULT_LONGITUDE);
        return;
      }

      const currentLocation = await Location.getCurrentPositionAsync({});
      setLocation({
        latitude: currentLocation.coords.latitude,
        longitude: currentLocation.coords.longitude,
      });
      await fetchSellers(
        currentLocation.coords.latitude,
        currentLocation.coords.longitude
      );
    } catch (error) {
      console.error('Error getting location:', error);
      setLocation({
        latitude: MAP_CONFIG.DEFAULT_LATITUDE,
        longitude: MAP_CONFIG.DEFAULT_LONGITUDE,
      });
      await fetchSellers(MAP_CONFIG.DEFAULT_LATITUDE, MAP_CONFIG.DEFAULT_LONGITUDE);
    }
  };

  const fetchSellers = async (lat: number, lng: number) => {
    try {
      const response = await api.getNearbySellers(lat, lng, MAP_CONFIG.DEFAULT_RADIUS_KM);
      setSellers(response.sellers);
    } catch (error: any) {
      console.error('Error fetching sellers:', error);
      Alert.alert('Erro', 'Não foi possível carregar os vendedores');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = async () => {
    if (!location) return;
    setRefreshing(true);
    await fetchSellers(location.latitude, location.longitude);
  };

  const handleSellerPress = (sellerId: number) => {
    // @ts-ignore - Navigation types are complex with nested navigators
    navigation.navigate('SellerDetail', { sellerId });
  };

  const handleFavoriteToggle = async (seller: SellerProfile) => {
    try {
      if (seller.is_favorited) {
        await api.removeFavorite('SellerProfile', seller.id);
      } else {
        await api.addFavorite('SellerProfile', seller.id);
      }

      // Update local state
      setSellers((prevSellers) =>
        prevSellers.map((s) =>
          s.id === seller.id ? { ...s, is_favorited: !s.is_favorited } : s
        )
      );
    } catch (error) {
      console.error('Error toggling favorite:', error);
      Alert.alert('Erro', 'Não foi possível atualizar favorito');
    }
  };

  const renderSellerCard = ({ item }: { item: SellerProfile }) => (
    <TouchableOpacity
      style={[styles.sellerCard, item.is_favorited && styles.sellerCardFavorited]}
      onPress={() => handleSellerPress(item.id)}
    >
      <View style={styles.sellerHeader}>
        <View style={styles.sellerInfo}>
          <Text style={styles.businessName}>{item.business_name}</Text>
          {item.verified && <Text style={styles.verifiedBadge}>✓ Verificado</Text>}
        </View>
        <TouchableOpacity onPress={() => handleFavoriteToggle(item)}>
          <Text style={styles.favoriteIcon}>{item.is_favorited ? '⭐' : '☆'}</Text>
        </TouchableOpacity>
      </View>

      {item.bio && <Text style={styles.bio} numberOfLines={2}>{item.bio}</Text>}

      {item.current_location && (
        <View style={styles.locationInfo}>
          <Text style={styles.locationName}>📍 {item.current_location.name}</Text>
          {item.distance_km !== undefined && (
            <Text style={styles.distance}>{item.distance_km.toFixed(1)} km</Text>
          )}
        </View>
      )}

      <View style={styles.footer}>
        {item.currently_active ? (
          <View style={styles.activeTag}>
            <Text style={styles.activeTagText}>🟢 Ativo agora</Text>
          </View>
        ) : (
          <View style={styles.inactiveTag}>
            <Text style={styles.inactiveTagText}>⚫ Inativo</Text>
          </View>
        )}

        {item.has_current_menu && (
          <Text style={styles.menuTag}>📋 Menu disponível</Text>
        )}
      </View>
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={styles.loadingText}>Carregando vendedores...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Vendedores Próximos</Text>
        <Text style={styles.subtitle}>
          {sellers.length} vendedor{sellers.length !== 1 ? 'es' : ''} encontrado
          {sellers.length !== 1 ? 's' : ''}
        </Text>
      </View>

      <FlatList
        data={sellers}
        renderItem={renderSellerCard}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={[COLORS.primary]}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>Nenhum vendedor ativo por perto</Text>
            <Text style={styles.emptySubtext}>
              Tente aumentar o raio de busca ou verifique mais tarde
            </Text>
          </View>
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.background,
  },
  loadingText: {
    marginTop: SPACING.md,
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
  },
  header: {
    padding: SPACING.lg,
    backgroundColor: COLORS.card,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  title: {
    fontSize: FONT_SIZES.xl,
    fontWeight: 'bold',
    color: COLORS.text,
  },
  subtitle: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginTop: SPACING.xs,
  },
  listContent: {
    padding: SPACING.md,
  },
  sellerCard: {
    backgroundColor: COLORS.card,
    borderRadius: 12,
    padding: SPACING.md,
    marginBottom: SPACING.md,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  sellerCardFavorited: {
    borderColor: COLORS.warning,
    borderWidth: 2,
  },
  sellerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.sm,
  },
  sellerInfo: {
    flex: 1,
  },
  businessName: {
    fontSize: FONT_SIZES.lg,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: SPACING.xs,
  },
  verifiedBadge: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.success,
    fontWeight: '600',
  },
  favoriteIcon: {
    fontSize: 24,
  },
  bio: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginBottom: SPACING.sm,
  },
  locationInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.sm,
  },
  locationName: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.text,
    flex: 1,
  },
  distance: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    fontWeight: '600',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  activeTag: {
    backgroundColor: '#E8F5E9',
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
    borderRadius: 6,
  },
  activeTagText: {
    fontSize: FONT_SIZES.xs,
    color: COLORS.success,
    fontWeight: '600',
  },
  inactiveTag: {
    backgroundColor: '#F5F5F5',
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
    borderRadius: 6,
  },
  inactiveTagText: {
    fontSize: FONT_SIZES.xs,
    color: COLORS.textLight,
    fontWeight: '600',
  },
  menuTag: {
    fontSize: FONT_SIZES.xs,
    color: COLORS.textLight,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: SPACING.xl * 2,
  },
  emptyText: {
    fontSize: FONT_SIZES.lg,
    color: COLORS.text,
    marginBottom: SPACING.sm,
  },
  emptySubtext: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    textAlign: 'center',
  },
});
