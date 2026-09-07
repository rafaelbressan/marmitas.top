import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react-native';
import { FavoritesScreen } from '../src/screens/FavoritesScreen';
import type { Dish, SellerProfile } from '../src/types';

const mockSeller: SellerProfile = {
  id: 1,
  business_name: 'Marmitas da Dona Ana',
  bio: 'Comida caseira',
  verified: true,
  currently_active: true,
  favorites_count: 3,
  has_current_menu: true,
};

const mockDish: Dish = {
  id: 7,
  name: 'Feijoada',
  description: 'Com couve e farofa',
  price: 24.5,
  available: true,
  favorites_count: 9,
  seller_profile: { id: 1, business_name: 'Marmitas da Dona Ana' },
};

const mockRemoveFavorite = jest.fn().mockResolvedValue(undefined);

jest.mock('../src/services/api', () => ({
  api: {
    getFavorites: () =>
      Promise.resolve({ dishes: [mockDish], sellers: [mockSeller] }),
    removeFavorite: (type: string, id: number) => mockRemoveFavorite(type, id),
  },
}));

beforeEach(() => {
  mockRemoveFavorite.mockClear();
});

test('renders both sections, each with the card for its own type', async () => {
  render(<FavoritesScreen />);

  expect(await screen.findByText('Vendedores Favoritos (1)', {}, { timeout: 15000 })).toBeTruthy();
  expect(screen.getByText('Pratos Favoritos (1)')).toBeTruthy();

  // seller card (renderSeller)
  expect(screen.getByText('Marmitas da Dona Ana')).toBeTruthy();
  expect(screen.getByText('Comida caseira')).toBeTruthy();
  expect(screen.getByText('🟢 Ativo agora')).toBeTruthy();
  expect(screen.getByText('✓ Verificado')).toBeTruthy();

  // dish card (renderDish)
  expect(screen.getByText('Feijoada')).toBeTruthy();
  expect(screen.getByText('por Marmitas da Dona Ana')).toBeTruthy();
  expect(screen.getByText('R$ 24,50')).toBeTruthy();
});

test('each card removes the favorite of its own type', async () => {
  render(<FavoritesScreen />);
  await screen.findByText('Vendedores Favoritos (1)', {}, { timeout: 15000 });

  const [sellerStar] = screen.getAllByText('⭐');

  fireEvent.press(sellerStar);
  await waitFor(() =>
    expect(mockRemoveFavorite).toHaveBeenCalledWith('SellerProfile', 1)
  );
  await waitFor(() => expect(screen.getByText('Vendedores Favoritos (0)')).toBeTruthy());

  // Only the dish star is left once the seller drops out of the list.
  const [dishStar] = screen.getAllByText('⭐');
  fireEvent.press(dishStar);
  await waitFor(() => expect(mockRemoveFavorite).toHaveBeenCalledWith('Dish', 7));
  await waitFor(() => expect(screen.getByText('Pratos Favoritos (0)')).toBeTruthy());
});
