import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Platform, Image, Pressable, Switch, Text, TextInput } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather, Ionicons } from '@expo/vector-icons';
import { useRides } from '@/context/RidesContext';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { BottomTabInset, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export default function ProfileScreen() {
  const { rides, currentUser, updateCurrentUser, logout } = useRides();
  const theme = useTheme();
  const safeAreaInsets = useSafeAreaInsets();

  // Local preferences states
  const [notifyMatches, setNotifyMatches] = useState(true);
  const [notifyChats, setNotifyChats] = useState(true);

  // Edit Mode States
  const [isEditing, setIsEditing] = useState(false);
  const [name, setName] = useState(currentUser?.name || '');
  const [phone, setPhone] = useState(currentUser?.phone || '');
  const [email, setEmail] = useState(currentUser?.email || '');
  const [photo, setPhoto] = useState(currentUser?.photo || '');
  const [gender, setGender] = useState<'Male' | 'Female' | 'Other'>(currentUser?.gender || 'Male');
  const [errorMsg, setErrorMsg] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);

  if (!currentUser) return null;

  const insets = {
    ...safeAreaInsets,
    bottom: safeAreaInsets.bottom + BottomTabInset + Spacing.three,
  };

  const contentPlatformStyle = Platform.select({
    android: {
      paddingTop: insets.top + Spacing.two,
      paddingLeft: insets.left,
      paddingRight: insets.right,
      paddingBottom: insets.bottom,
    },
    ios: {
      paddingTop: insets.top + Spacing.two,
      paddingLeft: insets.left,
      paddingRight: insets.right,
      paddingBottom: insets.bottom,
    },
    web: {
      paddingTop: Spacing.six,
      paddingBottom: Spacing.four,
    },
  });

  const handleImageUpload = () => {
    if (Platform.OS === 'web') {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'image/*';
      input.onchange = (e: any) => {
        const file = e.target.files?.[0];
        if (file) {
          const reader = new FileReader();
          reader.onload = (event) => {
            if (event.target?.result) {
              setPhoto(event.target.result as string);
            }
          };
          reader.readAsDataURL(file);
        }
      };
      input.click();
    } else {
      alert('Photo uploading is supported in the browser. For mobile platforms, please enter a custom Photo URL below.');
    }
  };

  const handleSave = () => {
    if (!name.trim()) {
      setErrorMsg('Name cannot be empty');
      return;
    }
    const numericPhone = phone.trim();
    if (!numericPhone) {
      setErrorMsg('Phone cannot be empty');
      return;
    }
    if (!/^\d{10}$/.test(numericPhone)) {
      setErrorMsg('Phone number must be exactly 10 digits');
      return;
    }
    if (!email.trim()) {
      setErrorMsg('Email cannot be empty');
      return;
    }
    if (!email.includes('@')) {
      setErrorMsg('Please enter a valid email');
      return;
    }

    setErrorMsg('');
    updateCurrentUser({
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      photo: photo.trim() || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      gender
    });

    setSaveSuccess(true);
    setIsEditing(false);
    setTimeout(() => {
      setSaveSuccess(false);
    }, 2500);
  };

  const handleCancel = () => {
    setName(currentUser.name);
    setPhone(currentUser.phone);
    setEmail(currentUser.email);
    setPhoto(currentUser.photo);
    setGender(currentUser.gender);
    setErrorMsg('');
    setIsEditing(false);
  };

  // Calculate statistics
  const sharedCount = rides.filter(r => r.poster.email === currentUser.email).length;
  const joinedCount = rides.filter(r => r.acceptor?.email === currentUser.email).length;

  return (
    <ScrollView
      style={[styles.scrollView, { backgroundColor: theme.background }]}
      contentInset={insets}
      contentContainerStyle={[styles.contentContainer, contentPlatformStyle]}
    >
      <ThemedView style={styles.container}>
        
        {saveSuccess && (
          <View style={[styles.successBanner, { backgroundColor: theme.success + '15', borderColor: theme.success }]}>
            <Feather name="check-circle" size={16} color={theme.success} />
            <Text style={[styles.successText, { color: theme.success }]}>Profile saved successfully & synced!</Text>
          </View>
        )}

        {/* Profile Card / Edit Form */}
        <ThemedView type="backgroundElement" style={[styles.profileCard, { borderColor: theme.border }]}>
          {isEditing ? (
            <View style={styles.formContainer}>
              <ThemedText type="smallBold" style={styles.formTitle}>Edit Profile Details</ThemedText>
              
              {errorMsg ? (
                <View style={[styles.formErrorBox, { backgroundColor: theme.danger + '15' }]}>
                  <Text style={[styles.formErrorText, { color: theme.danger }]}>{errorMsg}</Text>
                </View>
              ) : null}

              {/* Avatar Photo Selector */}
              <View style={styles.inputWrapper}>
                <ThemedText type="smallBold" themeColor="textSecondary" style={styles.inputLabel}>SELECT AVATAR IMAGE</ThemedText>
                <View style={styles.avatarSelectorRow}>
                  {[
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
                  ].map((url, idx) => (
                    <Pressable
                      key={url}
                      onPress={() => setPhoto(url)}
                      style={[
                        styles.avatarThumbWrapper,
                        { borderColor: theme.border },
                        photo === url && { borderColor: theme.primary, borderWidth: 2 }
                      ]}
                    >
                      <Image source={{ uri: url }} style={styles.avatarThumb} />
                    </Pressable>
                  ))}
                </View>

                <Pressable
                  style={[styles.uploadBtn, { borderColor: theme.primary, backgroundColor: theme.primary + '15' }]}
                  onPress={handleImageUpload}
                >
                  <Feather name="upload" size={14} color={theme.primary} style={{ marginRight: 6 }} />
                  <Text style={[styles.uploadBtnText, { color: theme.primary }]}>Upload Custom Profile Image</Text>
                </Pressable>

                <ThemedText type="smallBold" themeColor="textSecondary" style={[styles.inputLabel, { marginTop: Spacing.two }]}>
                  OR ENTER CUSTOM PHOTO URL
                </ThemedText>
                <TextInput
                  value={photo}
                  onChangeText={setPhoto}
                  placeholder="https://example.com/photo.jpg"
                  placeholderTextColor={theme.textSecondary}
                  style={[styles.textInput, { color: theme.text, borderColor: theme.border, backgroundColor: theme.background }]}
                />
              </View>

              {/* Name Input */}
              <View style={styles.inputWrapper}>
                <ThemedText type="smallBold" themeColor="textSecondary" style={styles.inputLabel}>FULL NAME</ThemedText>
                <TextInput
                  value={name}
                  onChangeText={setName}
                  placeholder="Daksh Karangiya"
                  placeholderTextColor={theme.textSecondary}
                  style={[styles.textInput, { color: theme.text, borderColor: theme.border, backgroundColor: theme.background }]}
                />
              </View>

              {/* Phone Input */}
              <View style={styles.inputWrapper}>
                <ThemedText type="smallBold" themeColor="textSecondary" style={styles.inputLabel}>PHONE NUMBER (10 DIGITS)</ThemedText>
                <TextInput
                  value={phone}
                  onChangeText={(text) => setPhone(text.replace(/\D/g, '').slice(0, 10))}
                  placeholder="9876543210"
                  placeholderTextColor={theme.textSecondary}
                  keyboardType="phone-pad"
                  maxLength={10}
                  style={[styles.textInput, { color: theme.text, borderColor: theme.border, backgroundColor: theme.background }]}
                />
              </View>

              {/* Email Input */}
              <View style={styles.inputWrapper}>
                <ThemedText type="smallBold" themeColor="textSecondary" style={styles.inputLabel}>EMAIL ADDRESS</ThemedText>
                <TextInput
                  value={email}
                  onChangeText={setEmail}
                  placeholder="daksh@autoshare.com"
                  placeholderTextColor={theme.textSecondary}
                  keyboardType="email-address"
                  style={[styles.textInput, { color: theme.text, borderColor: theme.border, backgroundColor: theme.background }]}
                />
              </View>



              {/* Buttons */}
              <View style={styles.formActions}>
                <Pressable
                  style={[styles.cancelFormBtn, { borderColor: theme.border }]}
                  onPress={handleCancel}
                >
                  <ThemedText type="smallBold" themeColor="textSecondary">Cancel</ThemedText>
                </Pressable>

                <Pressable
                  style={[styles.saveFormBtn, { backgroundColor: theme.primary }]}
                  onPress={handleSave}
                >
                  <Text style={styles.saveFormText}>Save Changes</Text>
                </Pressable>
              </View>
            </View>
          ) : (
            <View style={styles.profileViewContainer}>
              <Image source={{ uri: currentUser.photo }} style={styles.avatar} />
              <ThemedText type="subtitle" style={styles.name}>{currentUser.name}</ThemedText>
              <ThemedText themeColor="textSecondary" style={styles.memberSince}>
                Member since Jan 2026
              </ThemedText>

              <View style={[styles.contactsContainer, { backgroundColor: theme.background }]}>
                <View style={styles.contactItem}>
                  <Feather name="phone" size={14} color={theme.primary} />
                  <ThemedText type="small">
                    {(currentUser?.phone || '').length === 10
                      ? `+91 ${(currentUser?.phone || '').slice(0, 5)} ${(currentUser?.phone || '').slice(5)}`
                      : currentUser?.phone || ''}
                  </ThemedText>
                </View>
                <View style={styles.contactItem}>
                  <Feather name="mail" size={14} color={theme.primary} />
                  <ThemedText type="small">{currentUser.email}</ThemedText>
                </View>
              </View>

              <Pressable
                style={[styles.editProfileBtn, { backgroundColor: theme.primary + '15', borderColor: theme.primary }]}
                onPress={() => setIsEditing(true)}
              >
                <Feather name="edit-2" size={14} color={theme.primary} style={{ marginRight: 6 }} />
                <Text style={[styles.editProfileBtnText, { color: theme.primary }]}>Edit Profile Details</Text>
              </Pressable>
            </View>
          )}
        </ThemedView>

        {/* Stats Grid */}
        <View style={styles.statsGrid}>
          <ThemedView type="backgroundElement" style={[styles.statBox, { borderColor: theme.border }]}>
            <Text style={[styles.statNumber, { color: theme.primary }]}>{sharedCount}</Text>
            <ThemedText type="small" themeColor="textSecondary">Rides Shared</ThemedText>
          </ThemedView>

          <ThemedView type="backgroundElement" style={[styles.statBox, { borderColor: theme.border }]}>
            <Text style={[styles.statNumber, { color: theme.primary }]}>{joinedCount}</Text>
            <ThemedText type="small" themeColor="textSecondary">Rides Joined</ThemedText>
          </ThemedView>

          <ThemedView type="backgroundElement" style={[styles.statBox, { borderColor: theme.border }]}>
            <View style={styles.ratingRow}>
              <Text style={[styles.statNumber, { color: theme.warning }]}>4.9</Text>
              <Ionicons name="star" size={18} color={theme.warning} style={{ marginLeft: 2, marginTop: -4 }} />
            </View>
            <ThemedText type="small" themeColor="textSecondary">User Rating</ThemedText>
          </ThemedView>
        </View>

        {/* Settings Section */}
        <ThemedText type="smallBold" themeColor="textSecondary" style={styles.sectionLabel}>
          PREFERENCES & ALERTS
        </ThemedText>

        <ThemedView type="backgroundElement" style={[styles.settingsGroup, { borderColor: theme.border }]}>
          {/* Setting 1: Match Alerts */}
          <View style={styles.settingItem}>
            <View style={styles.settingLeft}>
              <View style={[styles.settingIcon, { backgroundColor: theme.primary + '15' }]}>
                <Feather name="bell" size={16} color={theme.primary} />
              </View>
              <View style={styles.settingTexts}>
                <ThemedText type="smallBold">Match Alerts</ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.settingDesc}>
                  Notify when a ride matches your route
                </ThemedText>
              </View>
            </View>
            <Switch
              value={notifyMatches}
              onValueChange={setNotifyMatches}
              trackColor={{ false: theme.border, true: theme.primary + '80' }}
              thumbColor={notifyMatches ? theme.primary : '#F4F3F4'}
            />
          </View>

          <View style={[styles.settingsDivider, { backgroundColor: theme.border }]} />

          {/* Setting 2: Chat Alerts */}
          <View style={styles.settingItem}>
            <View style={styles.settingLeft}>
              <View style={[styles.settingIcon, { backgroundColor: theme.primary + '15' }]}>
                <Ionicons name="chatbubble-outline" size={16} color={theme.primary} />
              </View>
              <View style={styles.settingTexts}>
                <ThemedText type="smallBold">Chat Notifications</ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.settingDesc}>
                  Get alerts for new coordination messages
                </ThemedText>
              </View>
            </View>
            <Switch
              value={notifyChats}
              onValueChange={setNotifyChats}
              trackColor={{ false: theme.border, true: theme.primary + '80' }}
              thumbColor={notifyChats ? theme.primary : '#F4F3F4'}
            />
          </View>

          <View style={[styles.settingsDivider, { backgroundColor: theme.border }]} />

          {/* Setting 3: Safety Guidelines */}
          <Pressable style={({ pressed }) => [styles.settingItem, pressed && { opacity: 0.7 }]}>
            <View style={styles.settingLeft}>
              <View style={[styles.settingIcon, { backgroundColor: theme.primary + '15' }]}>
                <Feather name="shield" size={16} color={theme.primary} />
              </View>
              <View style={styles.settingTexts}>
                <ThemedText type="smallBold">Carpool Safety Guidelines</ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.settingDesc}>
                  Verify details before stepping into shared cabs
                </ThemedText>
              </View>
            </View>
            <Feather name="chevron-right" size={18} color={theme.textSecondary} />
          </Pressable>
        </ThemedView>

        {/* Support Section */}
        <ThemedText type="smallBold" themeColor="textSecondary" style={styles.sectionLabel}>
          SUPPORT & LEGAL
        </ThemedText>

        <ThemedView type="backgroundElement" style={[styles.settingsGroup, { borderColor: theme.border }]}>
          <Pressable style={({ pressed }) => [styles.settingItem, pressed && { opacity: 0.7 }]}>
            <View style={styles.settingLeft}>
              <View style={[styles.settingIcon, { backgroundColor: theme.primary + '15' }]}>
                <Feather name="help-circle" size={16} color={theme.primary} />
              </View>
              <View style={styles.settingTexts}>
                <ThemedText type="smallBold">Help & Feedback</ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.settingDesc}>
                  Contact support team or report bugs
                </ThemedText>
              </View>
            </View>
            <Feather name="chevron-right" size={18} color={theme.textSecondary} />
          </Pressable>

          <View style={[styles.settingsDivider, { backgroundColor: theme.border }]} />

          <Pressable style={({ pressed }) => [styles.settingItem, pressed && { opacity: 0.7 }]}>
            <View style={styles.settingLeft}>
              <View style={[styles.settingIcon, { backgroundColor: theme.primary + '15' }]}>
                <Feather name="file-text" size={16} color={theme.primary} />
              </View>
              <View style={styles.settingTexts}>
                <ThemedText type="smallBold">Terms of Service</ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.settingDesc}>
                  Read AutoShare ride sharing terms
                </ThemedText>
              </View>
            </View>
            <Feather name="chevron-right" size={18} color={theme.textSecondary} />
          </Pressable>
        </ThemedView>

        <Pressable
          style={({ pressed }) => [
            styles.logoutBtn,
            { borderColor: theme.danger, backgroundColor: theme.danger + '10' },
            pressed && { backgroundColor: theme.danger + '20' }
          ]}
          onPress={logout}
        >
          <Feather name="log-out" size={16} color={theme.danger} style={{ marginRight: 8 }} />
          <Text style={[styles.logoutBtnText, { color: theme.danger }]}>Log Out</Text>
        </Pressable>

        <View style={styles.footer}>
          <ThemedText type="code" themeColor="textSecondary" style={styles.versionText}>
            AutoShare v1.0.0 Build 2026
          </ThemedText>
        </View>
      </ThemedView>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
  },
  container: {
    maxWidth: MaxContentWidth,
    flexGrow: 1,
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.four,
  },
  successBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.three,
    borderRadius: 14,
    borderWidth: 1,
    marginBottom: Spacing.four,
    gap: Spacing.two,
  },
  successText: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  profileCard: {
    borderRadius: 24,
    padding: Spacing.four,
    borderWidth: 1.5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 12,
    elevation: 3,
  },
  profileViewContainer: {
    alignItems: 'center',
    width: '100%',
  },
  avatar: {
    width: 90,
    height: 90,
    borderRadius: 45,
    borderWidth: 3,
    borderColor: '#0D9488',
    marginBottom: Spacing.three,
  },
  name: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  memberSince: {
    fontSize: 12,
    marginTop: 2,
    marginBottom: Spacing.four,
  },
  contactsContainer: {
    flexDirection: 'column',
    paddingVertical: Spacing.three,
    paddingHorizontal: Spacing.four,
    borderRadius: 16,
    width: '100%',
    gap: Spacing.two,
    marginBottom: Spacing.four,
  },
  contactItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
    width: '100%',
  },
  editProfileBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 40,
    borderRadius: 12,
    borderWidth: 1,
    width: '100%',
  },
  editProfileBtnText: {
    fontWeight: 'bold',
    fontSize: 13,
  },
  formContainer: {
    width: '100%',
  },
  formTitle: {
    fontSize: 18,
    marginBottom: Spacing.three,
  },
  formErrorBox: {
    padding: Spacing.two,
    borderRadius: 8,
    marginBottom: Spacing.three,
  },
  formErrorText: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  inputWrapper: {
    marginBottom: Spacing.three,
  },
  inputLabel: {
    fontSize: 9,
    letterSpacing: 0.5,
    marginBottom: Spacing.one,
  },
  textInput: {
    height: 44,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: Spacing.three,
    fontSize: 14,
  },
  formActions: {
    flexDirection: 'row',
    gap: Spacing.two,
    marginTop: Spacing.two,
  },
  cancelFormBtn: {
    flex: 1,
    height: 44,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  saveFormBtn: {
    flex: 1.5,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  saveFormText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 14,
  },
  statsGrid: {
    flexDirection: 'row',
    gap: Spacing.three,
    marginTop: Spacing.four,
    marginBottom: Spacing.five,
  },
  statBox: {
    flex: 1,
    borderRadius: 16,
    padding: Spacing.three,
    alignItems: 'center',
    borderWidth: 1.5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.02,
    shadowRadius: 6,
    elevation: 1,
  },
  statNumber: {
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 2,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  sectionLabel: {
    fontSize: 10,
    letterSpacing: 0.8,
    marginBottom: Spacing.two,
  },
  settingsGroup: {
    borderRadius: 20,
    borderWidth: 1.5,
    overflow: 'hidden',
    marginBottom: Spacing.five,
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.three,
    paddingHorizontal: Spacing.four,
  },
  settingLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.three,
    flex: 1,
  },
  settingIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  settingTexts: {
    flex: 1,
  },
  settingDesc: {
    fontSize: 12,
    marginTop: 1,
  },
  settingsDivider: {
    height: 1,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: Spacing.four,
  },
  versionText: {
    fontSize: 11,
  },
  avatarSelectorRow: {
    flexDirection: 'row',
    gap: Spacing.two,
    marginVertical: Spacing.one,
  },
  avatarThumbWrapper: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 1,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarThumb: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  genderSelectorRow: {
    flexDirection: 'row',
    gap: Spacing.two,
    marginVertical: Spacing.one,
  },
  genderChip: {
    flex: 1,
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  genderChipText: {
    fontSize: 13,
  },
  uploadBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 40,
    borderRadius: 12,
    borderWidth: 1.5,
    borderStyle: 'dashed',
    marginVertical: Spacing.two,
    width: '100%',
  },
  uploadBtnText: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 48,
    borderRadius: 14,
    borderWidth: 1.5,
    marginTop: Spacing.four,
    marginBottom: Spacing.two,
    width: '100%',
  },
  logoutBtnText: {
    fontWeight: 'bold',
    fontSize: 15,
  },
});
