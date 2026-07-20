import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Pressable, Platform, Text } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather, Ionicons } from '@expo/vector-icons';
import { useRides } from '@/context/RidesContext';
import { RideCard } from '@/components/RideCard';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { BottomTabInset, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export default function MyRidesScreen() {
  const { rides, currentUser, acceptRequest, declineRequest, cancelRide, completeRide, cancelRequest } = useRides();
  const theme = useTheme();
  
  if (!currentUser) return null;

  const safeAreaInsets = useSafeAreaInsets();

  const [activeTab, setActiveTab] = useState<'posted' | 'accepted'>('posted');

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

  // Filter rides based on active tab
  const postedRides = rides.filter(ride => ride.poster.email === currentUser.email);
  const acceptedRides = rides.filter(ride => ride.acceptor?.email === currentUser.email);
  const activeRidesList = activeTab === 'posted' ? postedRides : acceptedRides;



  return (
    <View style={[styles.mainContainer, { backgroundColor: theme.background }]}>
      <ScrollView
        style={styles.scrollView}
        contentInset={insets}
        contentContainerStyle={[styles.contentContainer, contentPlatformStyle]}
      >
        <ThemedView style={styles.container}>
          {/* Header */}
          <View style={styles.header}>
            <ThemedText type="subtitle">My Rides</ThemedText>
            <ThemedText themeColor="textSecondary" style={styles.headerDesc}>
              Manage and coordinate your carpools
            </ThemedText>
          </View>

          {/* Segmented Control */}
          <View style={[styles.segmentedWrapper, { backgroundColor: theme.backgroundElement, borderColor: theme.border }]}>
            <Pressable
              style={[
                styles.segmentBtn,
                activeTab === 'posted' && [styles.segmentBtnActive, { backgroundColor: theme.primary }]
              ]}
              onPress={() => setActiveTab('posted')}
            >
              <Feather
                name="send"
                size={14}
                color={activeTab === 'posted' ? '#FFFFFF' : theme.textSecondary}
                style={{ marginRight: 6 }}
              />
              <Text style={[
                styles.segmentText,
                { color: theme.textSecondary },
                activeTab === 'posted' && styles.segmentTextActive
              ]}>
                Posted by me ({postedRides.length})
              </Text>
            </Pressable>

            <Pressable
              style={[
                styles.segmentBtn,
                activeTab === 'accepted' && [styles.segmentBtnActive, { backgroundColor: theme.primary }]
              ]}
              onPress={() => setActiveTab('accepted')}
            >
              <Feather
                name="check-square"
                size={14}
                color={activeTab === 'accepted' ? '#FFFFFF' : theme.textSecondary}
                style={{ marginRight: 6 }}
              />
              <Text style={[
                styles.segmentText,
                { color: theme.textSecondary },
                activeTab === 'accepted' && styles.segmentTextActive
              ]}>
                Accepted by me ({acceptedRides.length})
              </Text>
            </Pressable>
          </View>

          {/* Ride List */}
          <View style={styles.listWrapper}>
            {activeRidesList.length > 0 ? (
              activeRidesList.map(ride => (
                <RideCard
                  key={ride.id}
                  ride={ride}
                  onAccept={() => {}}
                  onCancel={cancelRide}
                  onComplete={completeRide}
                  onAcceptRequest={acceptRequest}
                  onDeclineRequest={declineRequest}
                  onCancelRequest={cancelRequest}
                />
              ))
            ) : (
              <View style={[styles.emptyContainer, { borderColor: theme.border }]}>
                <View style={[styles.emptyIconContainer, { backgroundColor: theme.backgroundElement }]}>
                  <Ionicons
                    name={activeTab === 'posted' ? "paper-plane-outline" : "car-outline"}
                    size={48}
                    color={theme.primary + '80'}
                  />
                </View>
                <ThemedText type="smallBold" style={styles.emptyTitle}>
                  {activeTab === 'posted' ? 'No rides posted' : 'No rides joined'}
                </ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.emptyDesc}>
                  {activeTab === 'posted'
                    ? "You haven't requested any rides yet. Click on the Home tab to post a new request."
                    : "You haven't accepted any share requests. Browse the feed and join a ride to coordinate."}
                </ThemedText>
              </View>
            )}
          </View>
        </ThemedView>
      </ScrollView>

    </View>
  );
}

const styles = StyleSheet.create({
  mainContainer: {
    flex: 1,
  },
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
  },
  header: {
    paddingVertical: Spacing.four,
  },
  headerDesc: {
    fontSize: 14,
    marginTop: Spacing.one,
  },
  segmentedWrapper: {
    flexDirection: 'row',
    borderRadius: 14,
    padding: Spacing.one,
    borderWidth: 1,
    marginBottom: Spacing.four,
  },
  segmentBtn: {
    flex: 1,
    flexDirection: 'row',
    height: 40,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  segmentBtnActive: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  segmentText: {
    fontSize: 13,
    fontWeight: '600',
  },
  segmentTextActive: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  listWrapper: {
    gap: Spacing.two,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.six,
    paddingHorizontal: Spacing.four,
    borderRadius: 20,
    borderWidth: 1.5,
    borderStyle: 'dashed',
    marginTop: Spacing.two,
  },
  emptyIconContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.three,
  },
  emptyTitle: {
    fontSize: 16,
    marginBottom: Spacing.one,
  },
  emptyDesc: {
    textAlign: 'center',
    fontSize: 13,
    lineHeight: 18,
    maxWidth: 260,
  },
});
