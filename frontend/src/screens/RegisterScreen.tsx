import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { useAuth } from '../contexts/AuthContext';
import { COLORS, SPACING, FONT_SIZES } from '../constants';
import type { RegisterData } from '../types';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { RootStackParamList } from '../types';

type RegisterScreenNavigationProp = StackNavigationProp<RootStackParamList, 'Register'>;

interface Props {
  navigation: RegisterScreenNavigationProp;
}

export const RegisterScreen: React.FC<Props> = ({ navigation }) => {
  const { signUp } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState<'consumer' | 'seller'>('consumer');
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    if (!email || !password || !passwordConfirmation) {
      Alert.alert('Erro', 'Por favor, preencha todos os campos obrigatórios');
      return;
    }

    if (password !== passwordConfirmation) {
      Alert.alert('Erro', 'As senhas não coincidem');
      return;
    }

    if (password.length < 6) {
      Alert.alert('Erro', 'A senha deve ter no mínimo 6 caracteres');
      return;
    }

    setLoading(true);
    try {
      const userData: RegisterData = {
        email,
        password,
        password_confirmation: passwordConfirmation,
        name: name || undefined,
        role,
      };
      await signUp(userData);
    } catch (error: any) {
      const errorMessage =
        error.response?.data?.errors?.join(', ') ||
        error.response?.data?.error ||
        'Ocorreu um erro ao criar sua conta';
      Alert.alert('Erro ao criar conta', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.content}>
          <Text style={styles.title}>Criar Conta</Text>
          <Text style={styles.subtitle}>Junte-se à comunidade Marmitas.top</Text>

          <View style={styles.form}>
            <TextInput
              style={styles.input}
              placeholder="Nome (opcional)"
              value={name}
              onChangeText={setName}
              editable={!loading}
            />

            <TextInput
              style={styles.input}
              placeholder="Email *"
              value={email}
              onChangeText={setEmail}
              autoCapitalize="none"
              keyboardType="email-address"
              editable={!loading}
            />

            <TextInput
              style={styles.input}
              placeholder="Senha *"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              editable={!loading}
            />

            <TextInput
              style={styles.input}
              placeholder="Confirmar Senha *"
              value={passwordConfirmation}
              onChangeText={setPasswordConfirmation}
              secureTextEntry
              editable={!loading}
            />

            <Text style={styles.label}>Tipo de Conta</Text>
            <View style={styles.roleContainer}>
              <TouchableOpacity
                style={[styles.roleButton, role === 'consumer' && styles.roleButtonActive]}
                onPress={() => setRole('consumer')}
                disabled={loading}
              >
                <Text
                  style={[styles.roleButtonText, role === 'consumer' && styles.roleButtonTextActive]}
                >
                  Consumidor
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.roleButton, role === 'seller' && styles.roleButtonActive]}
                onPress={() => setRole('seller')}
                disabled={loading}
              >
                <Text
                  style={[styles.roleButtonText, role === 'seller' && styles.roleButtonTextActive]}
                >
                  Vendedor
                </Text>
              </TouchableOpacity>
            </View>

            <TouchableOpacity
              style={[styles.button, loading && styles.buttonDisabled]}
              onPress={handleRegister}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color={COLORS.card} />
              ) : (
                <Text style={styles.buttonText}>Cadastrar</Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.linkButton}
              onPress={() => navigation.navigate('Login')}
              disabled={loading}
            >
              <Text style={styles.linkText}>
                Já tem uma conta? <Text style={styles.linkTextBold}>Faça login</Text>
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scrollContent: {
    flexGrow: 1,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.xl,
  },
  title: {
    fontSize: FONT_SIZES.xxl,
    fontWeight: 'bold',
    color: COLORS.primary,
    textAlign: 'center',
    marginBottom: SPACING.sm,
  },
  subtitle: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
    textAlign: 'center',
    marginBottom: SPACING.xl,
  },
  form: {
    width: '100%',
  },
  input: {
    backgroundColor: COLORS.card,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.md,
    fontSize: FONT_SIZES.md,
    marginBottom: SPACING.md,
  },
  label: {
    fontSize: FONT_SIZES.md,
    color: COLORS.text,
    marginBottom: SPACING.sm,
    fontWeight: '600',
  },
  roleContainer: {
    flexDirection: 'row',
    marginBottom: SPACING.lg,
    gap: SPACING.md,
  },
  roleButton: {
    flex: 1,
    borderWidth: 2,
    borderColor: COLORS.border,
    borderRadius: 8,
    paddingVertical: SPACING.md,
    alignItems: 'center',
    backgroundColor: COLORS.card,
  },
  roleButtonActive: {
    borderColor: COLORS.primary,
    backgroundColor: COLORS.primary,
  },
  roleButtonText: {
    fontSize: FONT_SIZES.md,
    color: COLORS.text,
    fontWeight: '600',
  },
  roleButtonTextActive: {
    color: COLORS.card,
  },
  button: {
    backgroundColor: COLORS.primary,
    borderRadius: 8,
    paddingVertical: SPACING.md,
    alignItems: 'center',
    marginTop: SPACING.md,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: COLORS.card,
    fontSize: FONT_SIZES.lg,
    fontWeight: 'bold',
  },
  linkButton: {
    marginTop: SPACING.lg,
    alignItems: 'center',
  },
  linkText: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
  },
  linkTextBold: {
    color: COLORS.primary,
    fontWeight: 'bold',
  },
});
