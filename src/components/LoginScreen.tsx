import React, { useState } from 'react';
import { View, StyleSheet, Text, Image, Pressable, TextInput, ScrollView, Platform } from 'react-native';
import { Feather, Ionicons } from '@expo/vector-icons';
import { useRides, presetUsers, User } from '@/context/RidesContext';
import { useTheme } from '@/hooks/use-theme';
import { Spacing, MaxContentWidth } from '@/constants/theme';
import { ThemedText } from './themed-text';
import { ThemedView } from './themed-view';

export const LoginScreen: React.FC = () => {
  const theme = useTheme();
  const { login } = useRides();

  // Mode state: preset vs custom
  const [activeTab, setActiveTab] = useState<'presets' | 'custom'>('presets');

  // Custom User form state
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [gender, setGender] = useState<'Male' | 'Female' | 'Other'>('Male');
  const [photo, setPhoto] = useState('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150');
  const [errorMsg, setErrorMsg] = useState('');

  const handleCustomLogin = () => {
    if (!name.trim()) {
      setErrorMsg('Please enter your full name');
      return;
    }
    const numericPhone = phone.trim();
    if (!numericPhone) {
      setErrorMsg('Please enter your phone number');
      return;
    }
    if (!/^\d{10}$/.test(numericPhone)) {
      setErrorMsg('Phone number must be exactly 10 digits');
      return;
    }
    if (!email.trim() || !email.includes('@')) {
      setErrorMsg('Please enter a valid email address');
      return;
    }

    setErrorMsg('');
    login({
      name: name.trim(),
      phone: numericPhone,
      email: email.trim().toLowerCase(),
      gender,
      photo: photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'
    });
  };

  const handlePresetLogin = (user: User) => {
    login(user);
  };

  return (
    <ScrollView style={[styles.scrollView, { backgroundColor: theme.background }]}>
      <View style={styles.centerWrapper}>
        <View style={styles.container}>
          {/* Logo Header */}
          <View style={styles.header}>
            <View style={[styles.logoContainer, { backgroundColor: theme.primary + '15' }]}>
              <Ionicons name="car-sport" size={40} color={theme.primary} />
            </View>
            <Text style={[styles.title, { color: theme.text }]}>AutoShare</Text>
            <Text style={[styles.subtitle, { color: theme.textSecondary }]}>
              Fast, secure, and smart cab & auto pooling
            </Text>
          </View>

          {/* Segmented Control tab */}
          <View style={[styles.tabContainer, { backgroundColor: theme.backgroundElement, borderColor: theme.border }]}>
            <Pressable
              style={[
                styles.tabBtn,
                activeTab === 'presets' && [styles.tabBtnActive, { backgroundColor: theme.primary }]
              ]}
              onPress={() => setActiveTab('presets')}
            >
              <Text style={[
                styles.tabText,
                { color: theme.textSecondary },
                activeTab === 'presets' && styles.tabTextActive
              ]}>
                Quick Presets
              </Text>
            </Pressable>

            <Pressable
              style={[
                styles.tabBtn,
                activeTab === 'custom' && [styles.tabBtnActive, { backgroundColor: theme.primary }]
              ]}
              onPress={() => setActiveTab('custom')}
            >
              <Text style={[
                styles.tabText,
                { color: theme.textSecondary },
                activeTab === 'custom' && styles.tabTextActive
              ]}>
                Custom Login
              </Text>
            </Pressable>
          </View>

          {/* Tab Content */}
          {activeTab === 'presets' ? (
            <View style={styles.presetsList}>
              <Text style={[styles.sectionTitle, { color: theme.textSecondary }]}>
                Select an account to log in and start testing:
              </Text>
              
              {presetUsers.map((pUser) => (
                <Pressable
                  key={pUser.email}
                  style={({ pressed }) => [
                    styles.presetCard,
                    { borderColor: theme.border, backgroundColor: theme.backgroundElement },
                    pressed && { opacity: 0.8 }
                  ]}
                  onPress={() => handlePresetLogin(pUser)}
                >
                  <Image source={{ uri: pUser.photo }} style={styles.presetAvatar} />
                  <View style={styles.presetInfo}>
                    <Text style={[styles.presetName, { color: theme.text }]}>{pUser.name}</Text>
                    <Text style={[styles.presetRole, { color: theme.textSecondary }]}>
                      {pUser.gender} • {pUser.phone}
                    </Text>
                  </View>
                  <View style={[styles.chevronBadge, { backgroundColor: theme.primary + '15' }]}>
                    <Feather name="chevron-right" size={16} color={theme.primary} />
                  </View>
                </Pressable>
              ))}
            </View>
          ) : (
            <View style={styles.customForm}>
              <Text style={[styles.sectionTitle, { color: theme.textSecondary }]}>
                Enter your details to register or log in:
              </Text>

              {errorMsg ? (
                <View style={[styles.errorBox, { backgroundColor: theme.danger + '15' }]}>
                  <Text style={[styles.errorText, { color: theme.danger }]}>{errorMsg}</Text>
                </View>
              ) : null}

              {/* Custom Name */}
              <View style={styles.formItem}>
                <Text style={[styles.formLabel, { color: theme.textSecondary }]}>FULL NAME</Text>
                <View style={[styles.inputBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  <Feather name="user" size={16} color={theme.primary} style={styles.inputIcon} />
                  <TextInput
                    value={name}
                    onChangeText={setName}
                    placeholder="Enter full name"
                    placeholderTextColor={theme.textSecondary}
                    style={[styles.textInput, { color: theme.text }]}
                  />
                </View>
              </View>

              {/* Custom Phone */}
              <View style={styles.formItem}>
                <Text style={[styles.formLabel, { color: theme.textSecondary }]}>PHONE NUMBER (10 DIGITS)</Text>
                <View style={[styles.inputBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  <Feather name="phone" size={16} color={theme.primary} style={styles.inputIcon} />
                  <TextInput
                    value={phone}
                    onChangeText={(t) => setPhone(t.replace(/\D/g, '').slice(0, 10))}
                    placeholder="Enter phone number"
                    placeholderTextColor={theme.textSecondary}
                    keyboardType="phone-pad"
                    maxLength={10}
                    style={[styles.textInput, { color: theme.text }]}
                  />
                </View>
              </View>

              {/* Custom Email */}
              <View style={styles.formItem}>
                <Text style={[styles.formLabel, { color: theme.textSecondary }]}>EMAIL ADDRESS</Text>
                <View style={[styles.inputBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  <Feather name="mail" size={16} color={theme.primary} style={styles.inputIcon} />
                  <TextInput
                    value={email}
                    onChangeText={setEmail}
                    placeholder="Enter email address"
                    placeholderTextColor={theme.textSecondary}
                    keyboardType="email-address"
                    style={[styles.textInput, { color: theme.text }]}
                  />
                </View>
              </View>

              {/* Custom Gender Selector */}
              <View style={styles.formItem}>
                <Text style={[styles.formLabel, { color: theme.textSecondary }]}>GENDER</Text>
                <View style={styles.genderRow}>
                  {(['Male', 'Female', 'Other'] as const).map((g) => (
                    <Pressable
                      key={g}
                      style={[
                        styles.genderBtn,
                        { borderColor: theme.border },
                        gender === g && { backgroundColor: theme.primary, borderColor: theme.primary }
                      ]}
                      onPress={() => setGender(g)}
                    >
                      <Text style={[
                        styles.genderText,
                        { color: theme.text },
                        gender === g && { color: '#FFFFFF', fontWeight: 'bold' }
                      ]}>
                        {g}
                      </Text>
                    </Pressable>
                  ))}
                </View>
              </View>

              {/* Submit Button */}
              <Pressable
                style={[styles.loginBtn, { backgroundColor: theme.primary }]}
                onPress={handleCustomLogin}
              >
                <Text style={styles.loginBtnText}>Register & Login</Text>
              </Pressable>
            </View>
          )}

          <View style={{ height: 40 }} />
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
  },
  centerWrapper: {
    flexDirection: 'row',
    justifyContent: 'center',
    width: '100%',
  },
  container: {
    width: '100%',
    maxWidth: MaxContentWidth,
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.six + 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: Spacing.five,
  },
  logoContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.two,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 13,
    marginTop: Spacing.one,
    textAlign: 'center',
  },
  tabContainer: {
    flexDirection: 'row',
    borderRadius: 14,
    padding: Spacing.one,
    borderWidth: 1,
    marginBottom: Spacing.five,
  },
  tabBtn: {
    flex: 1,
    height: 40,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabBtnActive: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  tabText: {
    fontSize: 13,
    fontWeight: '600',
  },
  tabTextActive: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  presetsList: {
    gap: Spacing.two,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '600',
    marginBottom: Spacing.two,
  },
  presetCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.three,
    borderRadius: 16,
    borderWidth: 1.5,
  },
  presetAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
  },
  presetInfo: {
    flex: 1,
    marginLeft: Spacing.three,
  },
  presetName: {
    fontSize: 15,
    fontWeight: 'bold',
  },
  presetRole: {
    fontSize: 12,
    marginTop: 2,
  },
  chevronBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  customForm: {
    gap: Spacing.three,
  },
  errorBox: {
    padding: Spacing.two + 2,
    borderRadius: 10,
    marginBottom: Spacing.one,
  },
  errorText: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  formItem: {
    gap: Spacing.one,
  },
  formLabel: {
    fontSize: 9,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  inputBox: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 48,
    borderRadius: 12,
    borderWidth: 1.5,
    paddingHorizontal: Spacing.three,
  },
  inputIcon: {
    marginRight: Spacing.two,
  },
  textInput: {
    flex: 1,
    height: '100%',
    fontSize: 14,
  },
  genderRow: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  genderBtn: {
    flex: 1,
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  genderText: {
    fontSize: 13,
    fontWeight: '600',
  },
  loginBtn: {
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: Spacing.four,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  loginBtnText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 15,
  },
});

export default LoginScreen;
