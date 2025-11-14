import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { api } from '../services/api';
import { COLORS, SPACING, FONT_SIZES } from '../constants';
import type { SellerProfile, WeeklyMenu } from '../types';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { RouteProp } from '@react-navigation/native';
import type { HomeStackParamList } from '../types';

type SellerDetailScreenNavigationProp = StackNavigationProp<
  HomeStackParamList,
  'SellerDetail'
>;
type SellerDetailScreenRouteProp = RouteProp<HomeStackParamList, 'SellerDetail'>;

interface Props {
  navigation: SellerDetailScreenNavigationProp;
  route: SellerDetailScreenRouteProp;
}

export const SellerDetailScreen: React.FC<Props> = ({ navigation, route }) => {
  const { sellerId } = route.params;
  const [seller, setSeller] = useState<SellerProfile | null>(null);
  const [menus, setMenus] = useState<WeeklyMenu[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFavorited, setIsFavorited] = useState(false);

  useEffect(() => {
    loadSellerData();
  }, [sellerId]);

  const loadSellerData = async () => {
    try {
      const [sellerResponse, menusResponse] = await Promise.all([
        api.getSeller(sellerId),
        api.getSellerMenus(sellerId),
      ]);

      setSeller(sellerResponse.seller);
      setMenus(menusResponse.menus);
      setIsFavorited(sellerResponse.seller.is_favorited || false);
    } catch (error: any) {
      console.error('Error loading seller data:', error);
      Alert.alert('Erro', 'Não foi possível carregar os dados do vendedor');
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  };

  const handleFavoriteToggle = async () => {
    if (!seller) return;

    try {
      if (isFavorited) {
        await api.removeFavorite('SellerProfile', seller.id);
        setIsFavorited(false);
      } else {
        await api.addFavorite('SellerProfile', seller.id);
        setIsFavorited(true);
      }
    } catch (error) {
      console.error('Error toggling favorite:', error);
      Alert.alert('Erro', 'Não foi possível atualizar favorito');
    }
  };

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
      </View>
    );
  }

  if (!seller) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.errorText}>Vendedor não encontrado</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <View style={styles.titleContainer}>
            <Text style={styles.businessName}>{seller.business_name}</Text>
            {seller.verified && <Text style={styles.verifiedBadge}>✓ Verificado</Text>}
          </View>

          <TouchableOpacity onPress={handleFavoriteToggle} style={styles.favoriteButton}>
            <Text style={styles.favoriteIcon}>{isFavorited ? '⭐' : '☆'}</Text>
          </TouchableOpacity>
        </View>

        {seller.bio && <Text style={styles.bio}>{seller.bio}</Text>}

        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{seller.favorites_count}</Text>
            <Text style={styles.statLabel}>Favoritos</Text>
          </View>

          {seller.currently_active ? (
            <View style={[styles.statItem, styles.activeStatus]}>
              <Text style={styles.activeText}>🟢 Ativo Agora</Text>
            </View>
          ) : (
            <View style={[styles.statItem, styles.inactiveStatus]}>
              <Text style={styles.inactiveText}>⚫ Inativo</Text>
            </View>
          )}
        </View>
      </View>

      {seller.current_location && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>📍 Localização Atual</Text>
          <View style={styles.locationCard}>
            <Text style={styles.locationName}>{seller.current_location.name}</Text>
            {seller.current_location.address && (
              <Text style={styles.locationAddress}>{seller.current_location.address}</Text>
            )}

            {seller.arrived_at && (
              <Text style={styles.timeInfo}>
                Chegou às {new Date(seller.arrived_at).toLocaleTimeString('pt-BR', {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </Text>
            )}

            {seller.leaving_at && (
              <Text style={styles.timeInfo}>
                Sai às {new Date(seller.leaving_at).toLocaleTimeString('pt-BR', {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </Text>
            )}
          </View>
        </View>
      )}

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>📋 Cardápios</Text>
        {menus.length > 0 ? (
          menus.map((menu) => (
            <View key={menu.id} style={styles.menuCard}>
              <Text style={styles.menuDate}>
                Semana de {new Date(menu.week_start_date).toLocaleDateString('pt-BR')}
              </Text>
              <Text style={styles.dishCount}>
                {menu.dishes.length} prato{menu.dishes.length !== 1 ? 's' : ''}
              </Text>

              {menu.dishes.slice(0, 3).map((dish) => (
                <View key={dish.id} style={styles.dishItem}>
                  <Text style={styles.dishName}>{dish.name}</Text>
                  <Text style={styles.dishPrice}>
                    R$ {dish.price.toFixed(2).replace('.', ',')}
                  </Text>
                </View>
              ))}

              {menu.dishes.length > 3 && (
                <Text style={styles.moreText}>
                  +{menu.dishes.length - 3} prato{menu.dishes.length - 3 !== 1 ? 's' : ''}
                </Text>
              )}
            </View>
          ))
        ) : (
          <Text style={styles.emptyText}>Nenhum cardápio disponível</Text>
        )}
      </View>
    </ScrollView>
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
  errorText: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
  },
  header: {
    backgroundColor: COLORS.card,
    padding: SPACING.lg,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.md,
  },
  titleContainer: {
    flex: 1,
  },
  businessName: {
    fontSize: FONT_SIZES.xl,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: SPACING.xs,
  },
  verifiedBadge: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.success,
    fontWeight: '600',
  },
  favoriteButton: {
    padding: SPACING.sm,
  },
  favoriteIcon: {
    fontSize: 32,
  },
  bio: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
    marginBottom: SPACING.md,
    lineHeight: 22,
  },
  statsRow: {
    flexDirection: 'row',
    gap: SPACING.md,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: FONT_SIZES.lg,
    fontWeight: 'bold',
    color: COLORS.text,
  },
  statLabel: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
  },
  activeStatus: {
    backgroundColor: '#E8F5E9',
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    borderRadius: 8,
  },
  activeText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.success,
    fontWeight: '600',
  },
  inactiveStatus: {
    backgroundColor: '#F5F5F5',
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    borderRadius: 8,
  },
  inactiveText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    fontWeight: '600',
  },
  section: {
    padding: SPACING.lg,
  },
  sectionTitle: {
    fontSize: FONT_SIZES.lg,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: SPACING.md,
  },
  locationCard: {
    backgroundColor: COLORS.card,
    padding: SPACING.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  locationName: {
    fontSize: FONT_SIZES.md,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: SPACING.xs,
  },
  locationAddress: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginBottom: SPACING.sm,
  },
  timeInfo: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.text,
    marginTop: SPACING.xs,
  },
  menuCard: {
    backgroundColor: COLORS.card,
    padding: SPACING.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: SPACING.md,
  },
  menuDate: {
    fontSize: FONT_SIZES.md,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: SPACING.xs,
  },
  dishCount: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginBottom: SPACING.sm,
  },
  dishItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: SPACING.xs,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  dishName: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.text,
    flex: 1,
  },
  dishPrice: {
    fontSize: FONT_SIZES.sm,
    fontWeight: '600',
    color: COLORS.primary,
  },
  moreText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    fontStyle: 'italic',
    marginTop: SPACING.sm,
  },
  emptyText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    textAlign: 'center',
    padding: SPACING.lg,
  },
});
