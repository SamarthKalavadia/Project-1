import React, { useState } from 'react';
import { View, StyleSheet, Modal, Pressable, TextInput, ScrollView, Text } from 'react-native';
import { Feather, Ionicons } from '@expo/vector-icons';
import { Filters } from '@/context/RidesContext';
import { ThemedText } from './themed-text';
import { ThemedView } from './themed-view';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

interface FilterModalProps {
  visible: boolean;
  onClose: () => void;
  filters: Filters;
  onApply: (filters: Filters) => void;
  onClear: () => void;
}

const POPULAR_LOCATIONS = [
  "Central Metro Station",
  "Techno IT Park",
  "Greenwood Apartments",
  "City Shopping Mall",
  "International Airport T2",
  "University North Campus",
  "Sports Complex",
  "Metro Station Gate 3",
  "Downtown Core",
  "Tech Park Phase 1"
];

export const FilterModal: React.FC<FilterModalProps> = ({
  visible,
  onClose,
  filters,
  onApply,
  onClear
}) => {
  const theme = useTheme();

  // Local state for filters
  const [localPickup, setLocalPickup] = useState(filters.pickup);
  const [localDestination, setLocalDestination] = useState(filters.destination);
  const [localSeats, setLocalSeats] = useState<number | null>(filters.seats);
  const [localTimeSlot, setLocalTimeSlot] = useState<Filters['timeSlot']>(filters.timeSlot);


  // Suggestions state
  const [pickupFocused, setPickupFocused] = useState(false);
  const [destFocused, setDestFocused] = useState(false);

  const handleApply = () => {
    onApply({
      pickup: localPickup,
      destination: localDestination,
      seats: localSeats,
      timeSlot: localTimeSlot
    });
    onClose();
  };

  const handleClear = () => {
    setLocalPickup('');
    setLocalDestination('');
    setLocalSeats(null);
    setLocalTimeSlot('all');
    onClear();
    onClose();
  };

  const filteredPickupSuggestions = POPULAR_LOCATIONS.filter(loc => 
    loc.toLowerCase().includes(localPickup.toLowerCase()) && 
    localPickup.toLowerCase() !== loc.toLowerCase()
  );

  const filteredDestSuggestions = POPULAR_LOCATIONS.filter(loc => 
    loc.toLowerCase().includes(localDestination.toLowerCase()) && 
    localDestination.toLowerCase() !== loc.toLowerCase()
  );

  return (
    <Modal
      animationType="slide"
      transparent={true}
      visible={visible}
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <ThemedView type="backgroundElement" style={[styles.container, { borderTopColor: theme.border }]}>
          {/* Header handle */}
          <View style={[styles.handle, { backgroundColor: theme.border }]} />

          {/* Header */}
          <View style={styles.header}>
            <ThemedText type="subtitle" style={styles.title}>Filter Rides</ThemedText>
            <Pressable style={styles.closeBtn} onPress={onClose}>
              <Feather name="x" size={20} color={theme.text} />
            </Pressable>
          </View>

          <ScrollView style={styles.scrollContent} keyboardShouldPersistTaps="handled">
            {/* Pickup Input */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>PICKUP LOCATION</ThemedText>
              <View style={[styles.inputContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                <Ionicons name="location-outline" size={18} color={theme.primary} style={styles.inputIcon} />
                <TextInput
                  value={localPickup}
                  onChangeText={setLocalPickup}
                  placeholder="Where are you leaving from?"
                  placeholderTextColor={theme.textSecondary}
                  onFocus={() => { setPickupFocused(true); setDestFocused(false); }}
                  style={[styles.input, { color: theme.text }]}
                />
                {localPickup ? (
                  <Pressable onPress={() => setLocalPickup('')}>
                    <Feather name="x" size={16} color={theme.textSecondary} />
                  </Pressable>
                ) : null}
              </View>

              {/* Suggestions */}
              {pickupFocused && filteredPickupSuggestions.length > 0 && (
                <View style={[styles.suggestionsBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  {filteredPickupSuggestions.slice(0, 3).map((loc, idx) => (
                    <Pressable
                      key={idx}
                      style={[styles.suggestionItem, { borderBottomColor: theme.border }]}
                      onPress={() => {
                        setLocalPickup(loc);
                        setPickupFocused(false);
                      }}
                    >
                      <Feather name="map-pin" size={12} color={theme.textSecondary} style={{ marginRight: 6 }} />
                      <ThemedText type="small">{loc}</ThemedText>
                    </Pressable>
                  ))}
                </View>
              )}
            </View>

            {/* Destination Input */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>DESTINATION</ThemedText>
              <View style={[styles.inputContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                <Ionicons name="location" size={18} color={theme.danger} style={styles.inputIcon} />
                <TextInput
                  value={localDestination}
                  onChangeText={setLocalDestination}
                  placeholder="Where do you want to go?"
                  placeholderTextColor={theme.textSecondary}
                  onFocus={() => { setDestFocused(true); setPickupFocused(false); }}
                  style={[styles.input, { color: theme.text }]}
                />
                {localDestination ? (
                  <Pressable onPress={() => setLocalDestination('')}>
                    <Feather name="x" size={16} color={theme.textSecondary} />
                  </Pressable>
                ) : null}
              </View>

              {/* Suggestions */}
              {destFocused && filteredDestSuggestions.length > 0 && (
                <View style={[styles.suggestionsBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  {filteredDestSuggestions.slice(0, 3).map((loc, idx) => (
                    <Pressable
                      key={idx}
                      style={[styles.suggestionItem, { borderBottomColor: theme.border }]}
                      onPress={() => {
                        setLocalDestination(loc);
                        setDestFocused(false);
                      }}
                    >
                      <Feather name="map-pin" size={12} color={theme.textSecondary} style={{ marginRight: 6 }} />
                      <ThemedText type="small">{loc}</ThemedText>
                    </Pressable>
                  ))}
                </View>
              )}
            </View>

            {/* Seats Required Selector */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>SEATS AVAILABLE</ThemedText>
              <View style={styles.seatsRow}>
                {[null, 1, 2, 3, 4].map((num) => (
                  <Pressable
                    key={num ?? 'any'}
                    style={[
                      styles.seatChip,
                      { borderColor: theme.border },
                      localSeats === num && { backgroundColor: theme.primary, borderColor: theme.primary }
                    ]}
                    onPress={() => setLocalSeats(num)}
                  >
                    <Text style={[
                      styles.seatChipText,
                      { color: theme.text },
                      localSeats === num && { color: '#FFFFFF', fontWeight: 'bold' }
                    ]}>
                      {num === null ? 'Any' : `${num}+`}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            {/* Time Slots Selector */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>DEPARTURE TIME OF DAY</ThemedText>
              <View style={styles.timeSlotsGrid}>
                {([
                  { id: 'all', name: 'All Day', icon: 'sunny' },
                  { id: 'morning', name: 'Morning (6 AM - 12 PM)', icon: 'sunny-outline' },
                  { id: 'afternoon', name: 'Afternoon (12 PM - 5 PM)', icon: 'partly-sunny-outline' },
                  { id: 'evening', name: 'Evening (5 PM - 9 PM)', icon: 'moon-outline' },
                  { id: 'night', name: 'Night (9 PM - 6 AM)', icon: 'moon' }
                ] as const).map((slot) => (
                  <Pressable
                    key={slot.id}
                    style={[
                      styles.timeSlotChip,
                      { borderColor: theme.border, backgroundColor: theme.background },
                      localTimeSlot === slot.id && { backgroundColor: theme.primary, borderColor: theme.primary }
                    ]}
                    onPress={() => setLocalTimeSlot(slot.id)}
                  >
                    <Ionicons
                      name={slot.icon}
                      size={14}
                      color={localTimeSlot === slot.id ? '#FFFFFF' : theme.primary}
                    />
                    <Text style={[
                      styles.timeSlotText,
                      { color: theme.text },
                      localTimeSlot === slot.id && { color: '#FFFFFF', fontWeight: 'bold' }
                    ]}>
                      {slot.name}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>



            <View style={{ height: 40 }} />
          </ScrollView>

          {/* Action Buttons */}
          <View style={[styles.actions, { borderTopColor: theme.border }]}>
            <Pressable
              style={[styles.clearBtn, { borderColor: theme.border }]}
              onPress={handleClear}
            >
              <ThemedText type="smallBold" themeColor="textSecondary">Clear All</ThemedText>
            </Pressable>

            <Pressable
              style={[styles.applyBtn, { backgroundColor: theme.primary }]}
              onPress={handleApply}
            >
              <Text style={styles.applyBtnText}>Apply Filters</Text>
            </Pressable>
          </View>
        </ThemedView>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
    justifyContent: 'flex-end',
  },
  container: {
    borderTopLeftRadius: 30,
    borderTopRightRadius: 30,
    paddingTop: Spacing.two,
    maxHeight: '90%',
    borderTopWidth: 1.5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 10,
  },
  handle: {
    width: 40,
    height: 5,
    borderRadius: 2.5,
    alignSelf: 'center',
    marginBottom: Spacing.three,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.four,
    paddingBottom: Spacing.three,
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
  },
  closeBtn: {
    padding: Spacing.one,
  },
  scrollContent: {
    paddingHorizontal: Spacing.four,
  },
  inputSection: {
    marginBottom: Spacing.four,
  },
  label: {
    fontSize: 10,
    letterSpacing: 0.8,
    marginBottom: Spacing.two,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.5,
    borderRadius: 12,
    paddingHorizontal: Spacing.three,
    height: 48,
  },
  inputIcon: {
    marginRight: Spacing.two,
  },
  input: {
    flex: 1,
    fontSize: 15,
  },
  suggestionsBox: {
    borderWidth: 1,
    borderTopWidth: 0,
    borderBottomLeftRadius: 12,
    borderBottomRightRadius: 12,
    overflow: 'hidden',
  },
  suggestionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.three,
    borderBottomWidth: 1,
  },
  seatsRow: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  seatChip: {
    flex: 1,
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  seatChipText: {
    fontSize: 14,
  },
  timeSlotsGrid: {
    gap: Spacing.two,
  },
  timeSlotChip: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    paddingHorizontal: Spacing.three,
    gap: Spacing.two,
  },
  timeSlotText: {
    fontSize: 13,
  },
  actions: {
    flexDirection: 'row',
    padding: Spacing.four,
    borderTopWidth: 1,
    gap: Spacing.three,
  },
  clearBtn: {
    flex: 1,
    height: 48,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  applyBtn: {
    flex: 1.5,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  applyBtnText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
