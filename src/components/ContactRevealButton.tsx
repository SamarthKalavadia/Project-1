import React from 'react';
import { View, StyleSheet, Pressable, Text, Linking } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { useTheme } from '@/hooks/use-theme';
import { Spacing } from '@/constants/theme';

interface ContactRevealButtonProps {
  phone: string;
  email: string;
  userName: string;
}

export const ContactRevealButton: React.FC<ContactRevealButtonProps> = ({
  phone,
  email,
  userName
}) => {
  const theme = useTheme();

  const safePhone = phone || '';
  const formattedPhone = safePhone.length === 10
    ? `+91 ${safePhone.slice(0, 5)} ${safePhone.slice(5)}`
    : safePhone;

  const handleCall = () => {
    if (phone) {
      Linking.openURL(`tel:${phone}`).catch(() => {});
    }
  };

  const handleEmail = () => {
    if (email) {
      Linking.openURL(`mailto:${email}`).catch(() => {});
    }
  };

  return (
    <View style={[styles.wrapper, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
      <View style={styles.cardHeader}>
        <View style={[styles.unlockIconBadge, { backgroundColor: theme.success + '15' }]}>
          <Feather name="check-circle" size={12} color={theme.success} />
        </View>
        <Text style={[styles.revealHeaderTitle, { color: theme.textSecondary }]}>
          CONTACT INFO
        </Text>
      </View>

      <View style={styles.contactDetails}>
        <Pressable 
          onPress={handleCall}
          style={({ pressed }) => [
            styles.detailRow, 
            pressed && { backgroundColor: theme.border + '40' }
          ]}
        >
          <Feather name="phone" size={16} color={theme.primary} style={styles.icon} />
          <View style={styles.textContainer}>
            <Text style={[styles.label, { color: theme.textSecondary }]}>Phone Number</Text>
            <Text style={[styles.detailText, { color: theme.text }]}>
              {formattedPhone}
            </Text>
          </View>
          <Feather name="phone-call" size={16} color={theme.primary} style={styles.actionIcon} />
        </Pressable>

        <View style={[styles.separator, { backgroundColor: theme.border }]} />

        <Pressable 
          onPress={handleEmail}
          style={({ pressed }) => [
            styles.detailRow, 
            pressed && { backgroundColor: theme.border + '40' }
          ]}
        >
          <Feather name="mail" size={16} color={theme.primary} style={styles.icon} />
          <View style={styles.textContainer}>
            <Text style={[styles.label, { color: theme.textSecondary }]}>Email Address</Text>
            <Text style={[styles.detailText, { color: theme.text }]} numberOfLines={1}>
              {email}
            </Text>
          </View>
          <Feather name="external-link" size={14} color={theme.textSecondary} style={styles.actionIcon} />
        </Pressable>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    width: '100%',
    borderRadius: 14,
    borderWidth: 1,
    padding: Spacing.three,
    marginTop: Spacing.two,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
    marginBottom: Spacing.three,
  },
  unlockIconBadge: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  revealHeaderTitle: {
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  contactDetails: {
    gap: Spacing.two,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.two,
    borderRadius: 10,
  },
  icon: {
    marginRight: Spacing.three,
  },
  textContainer: {
    flex: 1,
  },
  label: {
    fontSize: 11,
    fontWeight: '500',
    marginBottom: 2,
  },
  detailText: {
    fontSize: 15,
    fontWeight: '600',
  },
  actionIcon: {
    marginLeft: Spacing.two,
  },
  separator: {
    height: 1,
    marginHorizontal: Spacing.two,
  },
});

export default ContactRevealButton;

