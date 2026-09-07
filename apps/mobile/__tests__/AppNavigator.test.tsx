import React from 'react';
import { act, render, screen } from '@testing-library/react-native';
import { AppNavigator } from '../src/navigation/AppNavigator';

jest.mock('../src/contexts/AuthContext', () => ({
  useAuth: () => ({ isAuthenticated: true, loading: false }),
}));

// The tab screens are not what this checks: only the tab bar icon is.
jest.mock('../src/screens', () => {
  const { Text } = require('react-native');
  const stub = (label: string) => () => <Text>{label}</Text>;
  return {
    LoginScreen: stub('login'),
    RegisterScreen: stub('register'),
    HomeScreen: stub('home'),
    MapScreen: stub('map'),
    SellerDetailScreen: stub('seller-detail'),
    FavoritesScreen: stub('favorites'),
    ProfileScreen: stub('profile'),
  };
});

test('the tab bar renders its icons without crashing', async () => {
  render(<AppNavigator />);

  // One emoji per tab: proves the icon is a <Text> and actually renders.
  expect((await screen.findAllByText('🏠', {}, { timeout: 15000 })).length).toBeGreaterThan(0);
  expect(screen.getAllByText('🗺️').length).toBeGreaterThan(0);
  expect(screen.getAllByText('⭐').length).toBeGreaterThan(0);
  expect(screen.getAllByText('👤').length).toBeGreaterThan(0);

  // The first tab's screen mounted along with it.
  expect(screen.getByText('home')).toBeTruthy();

  // Let the stack's opening animation settle inside act.
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, 600));
  });
});
