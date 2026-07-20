import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Pressable, Platform, Text, RefreshControl } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather, Ionicons } from '@expo/vector-icons';
import { useRides } from '@/context/RidesContext';
import { RideCard } from '@/components/RideCard';
import { FilterModal } from '@/components/FilterModal';
import { PostRideModal } from '@/components/PostRideModal';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { BottomTabInset, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export default function HomeScreen() {
  const { rides, filters, setFilters, clearFilters, requestToJoin, addRide, cancelRequest, acceptRequest, declineRequest } = useRides();
  const theme = useTheme();
  const safeAreaInsets = useSafeAreaInsets();

  // Modal Visibility States
  const [filterModalVisible, setFilterModalVisible] = useState(false);
  const [postModalVisible, setPostModalVisible] = useState(false);

  // Loading animation state for interactions
  const [refreshing, setRefreshing] = useState(false);

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

  // Calculate Time Slot based on timestamp hour
  const getRideTimeSlot = (timestamp: number): string => {
    const hour = new Date(timestamp).getHours();
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  };

  // Filter rides logic
  const filteredRides = rides
    .filter(ride => {
      // Only show pending rides in the public browse feed
      if (ride.status !== 'Pending') return false;

      // Filter by pickup
      if (filters.pickup && !ride.pickup.toLowerCase().includes(filters.pickup.toLowerCase())) {
        return false;
      }

      // Filter by destination
      if (filters.destination && !ride.destination.toLowerCase().includes(filters.destination.toLowerCase())) {
        return false;
      }

      // Filter by seats
      if (filters.seats && ride.seatsLeft < filters.seats) {
        return false;
      }

      // Filter by time slot
      if (filters.timeSlot !== 'all' && getRideTimeSlot(ride.departureTimestamp) !== filters.timeSlot) {
        return false;
      }

      return true;
    });

  const handleRefresh = () => {
    setRefreshing(true);
    setTimeout(() => {
      setRefreshing(false);
    }, 800);
  };

  const activeFiltersCount = [
    !!filters.pickup,
    !!filters.destination,
    filters.seats !== null,
    filters.timeSlot !== 'all'
  ].filter(Boolean).length;



  return (
    <View style={[styles.mainWrapper, { backgroundColor: theme.background }]}>
      {/* Sticky Top Filter Summary Bar */}
      <View style={[
        styles.stickyFilterBar,
        {
          backgroundColor: theme.backgroundElement,
          borderBottomColor: theme.border,
          paddingTop: Platform.OS === 'web' ? Spacing.three : safeAreaInsets.top + Spacing.two
        }
      ]}>
        <View style={styles.filterBarHeader}>
          <View style={styles.brandTitleRow}>
            <Text style={[styles.logoText, { color: theme.primary }]}>AutoShare</Text>
            <ThemedView type="primaryLight" style={styles.betaBadge}>
              <Text style={[styles.betaText, { color: theme.primary }]}>BETA</Text>
            </ThemedView>
          </View>

          <Pressable
            style={({ pressed }) => [
              styles.filterBtn,
              { borderColor: theme.border },
              activeFiltersCount > 0 && { borderColor: theme.primary, backgroundColor: theme.primary + '10' },
              pressed && { opacity: 0.7 }
            ]}
            onPress={() => setFilterModalVisible(true)}
          >
            <Feather
              name="filter"
              size={14}
              color={activeFiltersCount > 0 ? theme.primary : theme.textSecondary}
              style={{ marginRight: 6 }}
            />
            <Text style={[
              styles.filterBtnText,
              { color: theme.textSecondary },
              activeFiltersCount > 0 && { color: theme.primary, fontWeight: 'bold' }
            ]}>
              Filter{activeFiltersCount > 0 ? ` (${activeFiltersCount})` : ''}
            </Text>
          </Pressable>
        </View>

        {/* Short details on what is filtered */}
        {activeFiltersCount > 0 && (
          <View style={styles.activeFiltersRow}>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.filterChipsScroll}>
              {filters.pickup && (
                <View style={[styles.chip, { backgroundColor: theme.background, borderColor: theme.border }]}>
                  <Text style={[styles.chipText, { color: theme.text }]} numberOfLines={1}>From: {filters.pickup}</Text>
                  <Pressable onPress={() => setFilters(f => ({ ...f, pickup: '' }))}>
                    <Feather name="x" size={12} color={theme.textSecondary} />
                  </Pressable>
                </View>
              )}
              {filters.destination && (
                <View style={[styles.chip, { backgroundColor: theme.background, borderColor: theme.border }]}>
                  <Text style={[styles.chipText, { color: theme.text }]} numberOfLines={1}>To: {filters.destination}</Text>
                  <Pressable onPress={() => setFilters(f => ({ ...f, destination: '' }))}>
                    <Feather name="x" size={12} color={theme.textSecondary} />
                  </Pressable>
                </View>
              )}
              {filters.seats !== null && (
                <View style={[styles.chip, { backgroundColor: theme.background, borderColor: theme.border }]}>
                  <Text style={[styles.chipText, { color: theme.text }]}>{filters.seats}+ seats</Text>
                  <Pressable onPress={() => setFilters(f => ({ ...f, seats: null }))}>
                    <Feather name="x" size={12} color={theme.textSecondary} />
                  </Pressable>
                </View>
              )}
              {filters.timeSlot !== 'all' && (
                <View style={[styles.chip, { backgroundColor: theme.background, borderColor: theme.border }]}>
                  <Text style={[styles.chipText, { color: theme.text }]}>Slot: {filters.timeSlot}</Text>
                  <Pressable onPress={() => setFilters(f => ({ ...f, timeSlot: 'all' }))}>
                    <Feather name="x" size={12} color={theme.textSecondary} />
                  </Pressable>
                </View>
              )}
            </ScrollView>

            <Pressable onPress={clearFilters} style={styles.clearAllTextBtn}>
              <Text style={[styles.clearAllText, { color: theme.primary }]}>Clear</Text>
            </Pressable>
          </View>
        )}
      </View>

      {/* Main Feed Container */}
      <ScrollView
        style={styles.scrollView}
        contentInset={{ bottom: insets.bottom }}
        contentContainerStyle={[styles.contentContainer, contentPlatformStyle]}
        refreshControl={
          Platform.OS !== 'web' ? (
            <RefreshControl
              refreshing={refreshing}
              onRefresh={handleRefresh}
              tintColor={theme.primary}
              colors={[theme.primary]}
            />
          ) : undefined
        }
      >
        <ThemedView style={styles.container}>
          <View style={styles.welcomeBlock}>
            <ThemedText type="subtitle" style={styles.welcomeTitle}>Find a Cab/Auto Pool</ThemedText>
            <ThemedText themeColor="textSecondary" style={styles.welcomeDesc}>
              Join co-passengers heading your way and split costs
            </ThemedText>
          </View>

          {/* Feed list */}
          <View style={styles.feedWrapper}>
            {filteredRides.length > 0 ? (
              filteredRides.map(ride => (
                <RideCard
                  key={ride.id}
                  ride={ride}
                  onAccept={requestToJoin}
                  onCancelRequest={cancelRequest}
                  onAcceptRequest={acceptRequest}
                  onDeclineRequest={declineRequest}
                />
              ))
            ) : (
              <View style={[styles.emptyStateContainer, { borderColor: theme.border }]}>
                <View style={[styles.emptyIconCircle, { backgroundColor: theme.backgroundElement }]}>
                  <Ionicons name="search-outline" size={48} color={theme.primary + '80'} />
                </View>
                <ThemedText type="smallBold" style={styles.emptyTitle}>No matching ride requests</ThemedText>
                <ThemedText type="small" themeColor="textSecondary" style={styles.emptyDesc}>
                  Try clearing some filters, searching for a broader location, or post your own ride request to get joined!
                </ThemedText>
                <Pressable
                  style={[styles.emptyActionBtn, { backgroundColor: theme.primary }]}
                  onPress={clearFilters}
                >
                  <Text style={styles.emptyActionBtnText}>Clear All Filters</Text>
                </Pressable>
              </View>
            )}
          </View>

          <View style={{ height: 80 }} />
        </ThemedView>
      </ScrollView>

      {/* Floating Action Button (FAB) */}
      <Pressable
        style={({ pressed }) => [
          styles.fab,
          { 
            backgroundColor: theme.primary,
            bottom: Platform.OS === 'web' 
              ? Spacing.four 
              : BottomTabInset + safeAreaInsets.bottom + Spacing.four
          },
          pressed && { opacity: 0.9, transform: [{ scale: 0.96 }] }
        ]}
        onPress={() => setPostModalVisible(true)}
      >
        <Feather name="plus" size={24} color="#FFFFFF" style={{ marginRight: 6 }} />
        <Text style={styles.fabText}>Post Ride</Text>
      </Pressable>

      {/* FILTER MODAL */}
      <FilterModal
        visible={filterModalVisible}
        onClose={() => setFilterModalVisible(false)}
        filters={filters}
        onApply={setFilters}
        onClear={clearFilters}
      />

      {/* POST RIDE MODAL */}
      <PostRideModal
        visible={postModalVisible}
        onClose={() => setPostModalVisible(false)}
        onPost={addRide}
      />


    </View>
  );
}

const styles = StyleSheet.create({
  mainWrapper: {
    flex: 1,
  },
  stickyFilterBar: {
    paddingHorizontal: Spacing.four,
    paddingBottom: Spacing.three,
    borderBottomWidth: 1.5,
    zIndex: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 2,
  },
  filterBarHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  brandTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
  },
  logoText: {
    fontSize: 24,
    fontWeight: 'bold',
    letterSpacing: -0.5,
  },
  betaBadge: {
    paddingVertical: 1,
    paddingHorizontal: Spacing.one + 2,
    borderRadius: 6,
  },
  betaText: {
    fontSize: 9,
    fontWeight: 'bold',
  },
  filterBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
    paddingHorizontal: Spacing.three,
    borderRadius: 10,
    borderWidth: 1.5,
  },
  filterBtnText: {
    fontSize: 12,
    fontWeight: '600',
  },
  activeFiltersRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: Spacing.two,
    gap: Spacing.two,
  },
  filterChipsScroll: {
    flex: 1,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.one,
    paddingHorizontal: Spacing.two + 2,
    borderRadius: 8,
    borderWidth: 1,
    marginRight: Spacing.one,
    gap: Spacing.one,
  },
  chipText: {
    fontSize: 11,
    maxWidth: 100,
  },
  clearAllTextBtn: {
    paddingHorizontal: Spacing.one,
  },
  clearAllText: {
    fontSize: 12,
    fontWeight: 'bold',
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
  welcomeBlock: {
    paddingTop: Spacing.four,
    paddingBottom: Spacing.two,
  },
  welcomeTitle: {
    fontSize: 22,
    fontWeight: 'bold',
  },
  welcomeDesc: {
    fontSize: 14,
    marginTop: Spacing.one,
  },
  feedWrapper: {
    marginTop: Spacing.two,
  },
  emptyStateContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.six,
    paddingHorizontal: Spacing.four,
    borderRadius: 20,
    borderWidth: 1.5,
    borderStyle: 'dashed',
    marginTop: Spacing.four,
  },
  emptyIconCircle: {
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
    maxWidth: 280,
    marginBottom: Spacing.four,
  },
  emptyActionBtn: {
    paddingVertical: 10,
    paddingHorizontal: Spacing.four,
    borderRadius: 12,
  },
  emptyActionBtnText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 13,
  },
  fab: {
    position: 'absolute',
    bottom: Spacing.four,
    right: Spacing.four,
    flexDirection: 'row',
    height: 52,
    borderRadius: 26,
    paddingHorizontal: Spacing.four,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 5,
    zIndex: 100,
  },
  fabText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 15,
  },
});
