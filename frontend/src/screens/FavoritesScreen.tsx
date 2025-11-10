import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SectionList,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
  Alert,
} from 'react-native';
import { api } from '../services/api';
import { COLORS, SPACING, FONT_SIZES } from '../constants';
import type { Dish, SellerProfile } from '../types';

export const FavoritesScreen: React.FC = () => {
  const [favoriteDishes, setFavoriteDishes] = useState<Dish[]>([]);
  const [favoriteSellers, setFavoriteSellers] = useState<SellerProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadFavorites();
  }, []);

  const loadFavorites = async () => {
    try {
      const response = await api.getFavorites();
      setFavoriteDishes(response.dishes);
      setFavoriteSellers(response.sellers);
    } catch (error) {
      console.error('Error loading favorites:', error);
      Alert.alert('Erro', 'Não foi possível carregar seus favoritos');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    setRefreshing(true);
    loadFavorites();
  };

  const handleRemoveDish = async (dishId: number) => {
    try {
      await api.removeFavorite('Dish', dishId);
      setFavoriteDishes((prev) => prev.filter((dish) => dish.id !== dishId));
    } catch (error) {
      console.error('Error removing favorite dish:', error);
      Alert.alert('Erro', 'Não foi possível remover favorito');
    }
  };

  const handleRemoveSeller = async (sellerId: number) => {
    try {
      await api.removeFavorite('SellerProfile', sellerId);
      setFavoriteSellers((prev) => prev.filter((seller) => seller.id !== sellerId));
    } catch (error) {
      console.error('Error removing favorite seller:', error);
      Alert.alert('Erro', 'Não foi possível remover favorito');
    }
  };

  const renderDish = ({ item }: { item: Dish }) => (
    <View style={styles.dishCard}>
      <View style={styles.dishInfo}>
        <Text style={styles.dishName}>{item.name}</Text>
        <Text style={styles.sellerName}>por {item.seller_profile.business_name}</Text>
        {item.description && (
          <Text style={styles.dishDescription} numberOfLines={2}>
            {item.description}
          </Text>
        )}
        <Text style={styles.dishPrice}>R$ {item.price.toFixed(2).replace('.', ',')}</Text>
      </View>
      <TouchableOpacity onPress={() => handleRemoveDish(item.id)} style={styles.removeButton}>
        <Text style={styles.removeIcon}>⭐</Text>
      </TouchableOpacity>
    </View>
  );

  const renderSeller = ({ item }: { item: SellerProfile }) => (
    <View style={styles.sellerCard}>
      <View style={styles.sellerInfo}>
        <Text style={styles.businessName}>{item.business_name}</Text>
        {item.bio && (
          <Text style={styles.bio} numberOfLines={2}>
            {item.bio}
          </Text>
        )}
        <View style={styles.sellerMeta}>
          {item.currently_active ? (
            <Text style={styles.activeTag}>🟢 Ativo agora</Text>
          ) : (
            <Text style={styles.inactiveTag}>⚫ Inativo</Text>
          )}
          {item.verified && <Text style={styles.verifiedTag}>✓ Verificado</Text>}
        </View>
      </View>
      <TouchableOpacity onPress={() => handleRemoveSeller(item.id)} style={styles.removeButton}>
        <Text style={styles.removeIcon}>⭐</Text>
      </TouchableOpacity>
    </View>
  );

  const sections = [
    {
      title: `Vendedores Favoritos (${favoriteSellers.length})`,
      data: favoriteSellers,
      renderItem: renderSeller,
    },
    {
      title: `Pratos Favoritos (${favoriteDishes.length})`,
      data: favoriteDishes,
      renderItem: renderDish,
    },
  ];

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <SectionList
        sections={sections}
        keyExtractor={(item, index) => `${item.id}-${index}`}
        renderSectionHeader={({ section: { title } }) => (
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>{title}</Text>
          </View>
        )}
        renderItem={({ item, section }) => section.renderItem({ item })}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} colors={[COLORS.primary]} />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>Você ainda não tem favoritos</Text>
            <Text style={styles.emptySubtext}>
              Adicione vendedores e pratos aos favoritos para vê-los aqui
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
  listContent: {
    padding: SPACING.md,
  },
  sectionHeader: {
    backgroundColor: COLORS.background,
    paddingVertical: SPACING.md,
  },
  sectionTitle: {
    fontSize: FONT_SIZES.lg,
    fontWeight: 'bold',
    color: COLORS.text,
  },
  sellerCard: {
    backgroundColor: COLORS.card,
    borderRadius: 12,
    padding: SPACING.md,
    marginBottom: SPACING.md,
    borderWidth: 2,
    borderColor: COLORS.warning,
    flexDirection: 'row',
    alignItems: 'center',
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
  bio: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginBottom: SPACING.sm,
  },
  sellerMeta: {
    flexDirection: 'row',
    gap: SPACING.sm,
  },
  activeTag: {
    fontSize: FONT_SIZES.xs,
    color: COLORS.success,
    fontWeight: '600',
  },
  inactiveTag: {
    fontSize: FONT_SIZES.xs,
    color: COLORS.textLight,
    fontWeight: '600',
  },
  verifiedTag: {
    fontSize: FONT_SIZES.xs,
    color: COLORS.success,
    fontWeight: '600',
  },
  dishCard: {
    backgroundColor: COLORS.card,
    borderRadius: 12,
    padding: SPACING.md,
    marginBottom: SPACING.md,
    borderWidth: 2,
    borderColor: COLORS.warning,
    flexDirection: 'row',
    alignItems: 'center',
  },
  dishInfo: {
    flex: 1,
  },
  dishName: {
    fontSize: FONT_SIZES.md,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: SPACING.xs,
  },
  sellerName: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginBottom: SPACING.xs,
  },
  dishDescription: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textLight,
    marginBottom: SPACING.sm,
  },
  dishPrice: {
    fontSize: FONT_SIZES.md,
    fontWeight: 'bold',
    color: COLORS.primary,
  },
  removeButton: {
    padding: SPACING.sm,
  },
  removeIcon: {
    fontSize: 24,
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
