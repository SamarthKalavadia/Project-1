import React, { useState } from 'react';
import { View, StyleSheet, Modal, Pressable, TextInput, ScrollView, Text, ActivityIndicator } from 'react-native';
import { Feather, Ionicons } from '@expo/vector-icons';
import { ThemedText } from './themed-text';
import { ThemedView } from './themed-view';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

interface PostRideModalProps {
  visible: boolean;
  onClose: () => void;
  onPost: (ride: {
    pickup: string;
    destination: string;
    departureTime: string;
    departureTimestamp: number;
    seatsTotal: number;
    seatsLeft: number;
    fareEstimate: string;
    notes: string;
    genderPreference: 'Boys only' | 'Girls only' | 'Both';
  }) => void;
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

export const PostRideModal: React.FC<PostRideModalProps> = ({
  visible,
  onClose,
  onPost
}) => {
  const theme = useTheme();

  // Form fields state
  const [pickup, setPickup] = useState('');
  const [destination, setDestination] = useState('');
  const [seats, setSeats] = useState(2);
  const [fare, setFare] = useState('');
  const [notes, setNotes] = useState('');
  const [genderPreference, setGenderPreference] = useState<'Boys only' | 'Girls only' | 'Both'>('Both');

  // Calendar Picker states
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [currentMonth, setCurrentMonth] = useState<Date>(new Date());

  // Time selection state
  const [hour, setHour] = useState('06');
  const [minute, setMinute] = useState('30');
  const [ampm, setAmpm] = useState<'AM' | 'PM'>('PM');

  // Input Suggestion states
  const [pickupFocused, setPickupFocused] = useState(false);
  const [destFocused, setDestFocused] = useState(false);

  // Loading state
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const filteredPickupSuggestions = POPULAR_LOCATIONS.filter(loc => 
    loc.toLowerCase().includes(pickup.toLowerCase()) && 
    pickup.toLowerCase() !== loc.toLowerCase()
  );

  const filteredDestSuggestions = POPULAR_LOCATIONS.filter(loc => 
    loc.toLowerCase().includes(destination.toLowerCase()) && 
    destination.toLowerCase() !== loc.toLowerCase()
  );

  // Calendar Helpers
  const year = currentMonth.getFullYear();
  const month = currentMonth.getMonth();

  const getDaysInMonth = (y: number, m: number) => new Date(y, m + 1, 0).getDate();
  const getFirstDayIndex = (y: number, m: number) => new Date(y, m, 1).getDay();

  const daysInMonth = getDaysInMonth(year, month);
  const firstDayIndex = getFirstDayIndex(year, month);

  const calendarCells = [];
  for (let i = 0; i < firstDayIndex; i++) {
    calendarCells.push({ type: 'empty', id: `empty-${i}` });
  }
  for (let d = 1; d <= daysInMonth; d++) {
    calendarCells.push({ type: 'day', dayNum: d, id: `day-${d}` });
  }

  const handlePrevMonth = () => {
    setCurrentMonth(new Date(year, month - 1, 1));
  };

  const handleNextMonth = () => {
    setCurrentMonth(new Date(year, month + 1, 1));
  };

  const isDatePast = (dayNum: number) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const target = new Date(year, month, dayNum);
    return target < today;
  };

  const isDateSelected = (dayNum: number) => {
    return (
      selectedDate.getDate() === dayNum &&
      selectedDate.getMonth() === month &&
      selectedDate.getFullYear() === year
    );
  };

  const handlePost = () => {
    // Form validation
    if (!pickup.trim()) {
      setErrorMsg('Please enter a pickup location');
      return;
    }
    if (!destination.trim()) {
      setErrorMsg('Please enter a destination');
      return;
    }
    if (pickup.trim().toLowerCase() === destination.trim().toLowerCase()) {
      setErrorMsg('Pickup and destination cannot be the same');
      return;
    }
    if (!hour.trim() || !minute.trim()) {
      setErrorMsg('Please select a valid time');
      return;
    }

    const hr = parseInt(hour);
    const min = parseInt(minute);
    if (isNaN(hr) || hr < 1 || hr > 12) {
      setErrorMsg('Hour must be between 1 and 12');
      return;
    }
    if (isNaN(min) || min < 0 || min > 59) {
      setErrorMsg('Minute must be between 0 and 59');
      return;
    }

    setErrorMsg('');
    setLoading(true);

    // Formulate departure time label (e.g. "Jul 18, 06:30 PM")
    const formattedHour = hour.padStart(2, '0');
    const formattedMinute = minute.padStart(2, '0');
    const monthName = selectedDate.toLocaleDateString('en-US', { month: 'short' });
    const dayNum = selectedDate.getDate();
    const departureTime = `${monthName} ${dayNum}, ${formattedHour}:${formattedMinute} ${ampm}`;

    // Timestamp formulation
    let baseDate = new Date(selectedDate);
    let hr24 = hr;
    if (ampm === 'PM' && hr !== 12) hr24 += 12;
    if (ampm === 'AM' && hr === 12) hr24 = 0;
    baseDate.setHours(hr24, min, 0, 0);

    const departureTimestamp = baseDate.getTime();
    const fareEstimate = fare.trim() ? (fare.includes('₹') ? fare.trim() : `₹${fare.trim()}`) : '₹50 - ₹100';

    setTimeout(() => {
      onPost({
        pickup: pickup.trim(),
        destination: destination.trim(),
        departureTime,
        departureTimestamp,
        seatsTotal: seats,
        seatsLeft: seats,
        fareEstimate,
        notes: notes.trim(),
        genderPreference
      });

      // Clear Form
      setPickup('');
      setDestination('');
      setSeats(2);
      setFare('');
      setNotes('');
      setHour('06');
      setMinute('30');
      setAmpm('PM');
      setSelectedDate(new Date());
      setCurrentMonth(new Date());
      setGenderPreference('Both');
      setLoading(false);
      onClose();
    }, 1000);
  };

  const monthLabel = currentMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

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
            <ThemedText type="subtitle" style={styles.title}>Post a Ride Request</ThemedText>
            <Pressable style={styles.closeBtn} onPress={onClose}>
              <Feather name="x" size={20} color={theme.text} />
            </Pressable>
          </View>

          <ScrollView style={styles.scrollContent} keyboardShouldPersistTaps="handled">
            {errorMsg ? (
              <View style={[styles.errorBox, { backgroundColor: theme.danger + '15' }]}>
                <Feather name="alert-triangle" size={16} color={theme.danger} />
                <Text style={[styles.errorText, { color: theme.danger }]}>{errorMsg}</Text>
              </View>
            ) : null}

            {/* Pickup */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>PICKUP LOCATION</ThemedText>
              <View style={[styles.inputContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                <Ionicons name="location-outline" size={18} color={theme.primary} style={styles.inputIcon} />
                <TextInput
                  value={pickup}
                  onChangeText={setPickup}
                  placeholder="Where are you starting from?"
                  placeholderTextColor={theme.textSecondary}
                  onFocus={() => { setPickupFocused(true); setDestFocused(false); }}
                  style={[styles.input, { color: theme.text }]}
                />
              </View>

              {pickupFocused && filteredPickupSuggestions.length > 0 && (
                <View style={[styles.suggestionsBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  {filteredPickupSuggestions.slice(0, 3).map((loc, idx) => (
                    <Pressable
                      key={idx}
                      style={[styles.suggestionItem, { borderBottomColor: theme.border }]}
                      onPress={() => {
                        setPickup(loc);
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

            {/* Destination */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>DESTINATION</ThemedText>
              <View style={[styles.inputContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                <Ionicons name="location" size={18} color={theme.danger} style={styles.inputIcon} />
                <TextInput
                  value={destination}
                  onChangeText={setDestination}
                  placeholder="Where is your drop-off?"
                  placeholderTextColor={theme.textSecondary}
                  onFocus={() => { setDestFocused(true); setPickupFocused(false); }}
                  style={[styles.input, { color: theme.text }]}
                />
              </View>

              {destFocused && filteredDestSuggestions.length > 0 && (
                <View style={[styles.suggestionsBox, { borderColor: theme.border, backgroundColor: theme.backgroundElement }]}>
                  {filteredDestSuggestions.slice(0, 3).map((loc, idx) => (
                    <Pressable
                      key={idx}
                      style={[styles.suggestionItem, { borderBottomColor: theme.border }]}
                      onPress={() => {
                        setDestination(loc);
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

            {/* Departure Date Calendar */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>
                CHOOSE RIDE DATE: {selectedDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })}
              </ThemedText>
              
              <View style={[styles.calendarContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                {/* Month navigation */}
                <View style={styles.calendarHeader}>
                  <Pressable onPress={handlePrevMonth} style={styles.monthNavBtn}>
                    <Feather name="chevron-left" size={18} color={theme.text} />
                  </Pressable>
                  <Text style={[styles.calendarMonthText, { color: theme.text }]}>
                    {monthLabel}
                  </Text>
                  <Pressable onPress={handleNextMonth} style={styles.monthNavBtn}>
                    <Feather name="chevron-right" size={18} color={theme.text} />
                  </Pressable>
                </View>

                {/* Weekday labels */}
                <View style={styles.weekdaysRow}>
                  {['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((wd) => (
                    <Text key={wd} style={[styles.weekdayText, { color: theme.textSecondary }]}>
                      {wd}
                    </Text>
                  ))}
                </View>

                {/* Days Grid */}
                <View style={styles.daysGrid}>
                  {calendarCells.map((cell) => {
                    if (cell.type === 'empty') {
                      return <View key={cell.id} style={styles.dayCell} />;
                    }

                    const dNum = cell.dayNum!;
                    const past = isDatePast(dNum);
                    const selected = isDateSelected(dNum);

                    return (
                      <Pressable
                        key={cell.id}
                        disabled={past}
                        style={[
                          styles.dayCell,
                          selected && [styles.selectedDayCell, { backgroundColor: theme.primary }],
                          past && { opacity: 0.25 }
                        ]}
                        onPress={() => {
                          setSelectedDate(new Date(year, month, dNum));
                        }}
                      >
                        <Text style={[
                          styles.dayCellText,
                          { color: theme.text },
                          selected && styles.selectedDayCellText
                        ]}>
                          {dNum}
                        </Text>
                      </Pressable>
                    );
                  })}
                </View>
              </View>
            </View>

            {/* Custom Time Spinners */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>DEPARTURE TIME</ThemedText>
              <View style={styles.timeInputRow}>
                <View style={[styles.timeBox, { borderColor: theme.border, backgroundColor: theme.background }]}>
                  <TextInput
                    value={hour}
                    onChangeText={setHour}
                    keyboardType="numeric"
                    maxLength={2}
                    placeholder="06"
                    placeholderTextColor={theme.textSecondary}
                    style={[styles.timeText, { color: theme.text }]}
                  />
                  <ThemedText type="small" themeColor="textSecondary">HH</ThemedText>
                </View>

                <ThemedText type="subtitle" style={styles.colon}>:</ThemedText>

                <View style={[styles.timeBox, { borderColor: theme.border, backgroundColor: theme.background }]}>
                  <TextInput
                    value={minute}
                    onChangeText={setMinute}
                    keyboardType="numeric"
                    maxLength={2}
                    placeholder="30"
                    placeholderTextColor={theme.textSecondary}
                    style={[styles.timeText, { color: theme.text }]}
                  />
                  <ThemedText type="small" themeColor="textSecondary">MM</ThemedText>
                </View>

                <View style={styles.ampmColumn}>
                  {(['AM', 'PM'] as const).map((a) => (
                    <Pressable
                      key={a}
                      style={[
                        styles.ampmBtn,
                        { borderColor: theme.border },
                        ampm === a && { backgroundColor: theme.primary, borderColor: theme.primary }
                      ]}
                      onPress={() => setAmpm(a)}
                    >
                      <Text style={[
                        styles.ampmText,
                        { color: theme.text },
                        ampm === a && { color: '#FFFFFF', fontWeight: 'bold' }
                      ]}>
                        {a}
                      </Text>
                    </Pressable>
                  ))}
                </View>
              </View>
            </View>

            {/* Seats Count */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>SEATS AVAILABLE</ThemedText>
              <View style={styles.counterRow}>
                <Pressable
                  style={[styles.counterBtn, { borderColor: theme.border }]}
                  onPress={() => setSeats(prev => Math.max(1, prev - 1))}
                >
                  <Feather name="minus" size={18} color={theme.text} />
                </Pressable>

                <ThemedText type="subtitle" style={styles.counterValue}>{seats}</ThemedText>

                <Pressable
                  style={[styles.counterBtn, { borderColor: theme.border }]}
                  onPress={() => setSeats(prev => Math.min(6, prev + 1))}
                >
                  <Feather name="plus" size={18} color={theme.text} />
                </Pressable>
              </View>
            </View>

            {/* Fare Split Estimate */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>FARE SPLIT ESTIMATE (OPTIONAL)</ThemedText>
              <View style={[styles.inputContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                <Ionicons name="card-outline" size={18} color={theme.primary} style={styles.inputIcon} />
                <TextInput
                  value={fare}
                  onChangeText={setFare}
                  placeholder="e.g. ₹50 - ₹80 or ₹60/person"
                  placeholderTextColor={theme.textSecondary}
                  style={[styles.input, { color: theme.text }]}
                />
              </View>
            </View>

            {/* Gender Preference */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>GENDER PREFERENCE</ThemedText>
              <View style={styles.genderPreferenceRow}>
                {(['Both', 'Boys only', 'Girls only'] as const).map((pref) => (
                  <Pressable
                    key={pref}
                    style={[
                      styles.genderPreferenceBtn,
                      { borderColor: theme.border },
                      genderPreference === pref && { backgroundColor: theme.primary, borderColor: theme.primary }
                    ]}
                    onPress={() => setGenderPreference(pref)}
                  >
                    <Text style={[
                      styles.genderPreferenceText,
                      { color: theme.text },
                      genderPreference === pref && { color: '#FFFFFF', fontWeight: 'bold' }
                    ]}>
                      {pref === 'Both' ? '👥 Both' : pref === 'Boys only' ? '🙋‍♂️ Boys only' : '🙋‍♀️ Girls only'}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            {/* Notes */}
            <View style={styles.inputSection}>
              <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>RIDE NOTES / PREFERENCES</ThemedText>
              <View style={[styles.inputContainer, styles.textAreaContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
                <TextInput
                  value={notes}
                  onChangeText={setNotes}
                  placeholder="e.g. Only 2 people in back seat, AC Cab, split equally."
                  placeholderTextColor={theme.textSecondary}
                  multiline={true}
                  numberOfLines={3}
                  style={[styles.input, styles.textArea, { color: theme.text }]}
                />
              </View>
            </View>

            <View style={{ height: 40 }} />
          </ScrollView>

          {/* Action Footer */}
          <View style={[styles.actions, { borderTopColor: theme.border }]}>
            <Pressable
              style={[styles.cancelBtn, { borderColor: theme.border }]}
              onPress={onClose}
              disabled={loading}
            >
              <ThemedText type="smallBold" themeColor="textSecondary">Discard</ThemedText>
            </Pressable>

            <Pressable
              style={[styles.submitBtn, { backgroundColor: theme.primary }]}
              onPress={handlePost}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color="#FFFFFF" size="small" />
              ) : (
                <Text style={styles.submitBtnText}>Post Request</Text>
              )}
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
    maxHeight: '92%',
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
  errorBox: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.three,
    borderRadius: 12,
    marginBottom: Spacing.four,
    gap: Spacing.two,
  },
  errorText: {
    fontSize: 14,
    fontWeight: 'bold',
    flex: 1,
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
  daySegmentRow: {
    flexDirection: 'row',
    gap: Spacing.two,
    marginBottom: Spacing.three,
  },
  dayButton: {
    flex: 1,
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dayText: {
    fontSize: 14,
  },
  timeInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.three,
  },
  timeBox: {
    flex: 1,
    height: 56,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    paddingBottom: Spacing.one,
  },
  timeText: {
    fontSize: 20,
    fontWeight: 'bold',
    textAlign: 'center',
    width: '100%',
    padding: 0,
  },
  colon: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  ampmColumn: {
    flexDirection: 'row',
    gap: Spacing.one,
  },
  ampmBtn: {
    width: 44,
    height: 44,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ampmText: {
    fontSize: 12,
  },
  counterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.four,
  },
  counterBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  counterValue: {
    fontSize: 22,
    fontWeight: 'bold',
    width: 30,
    textAlign: 'center',
  },
  textAreaContainer: {
    height: 90,
    alignItems: 'flex-start',
    paddingVertical: Spacing.two,
  },
  textArea: {
    height: '100%',
    textAlignVertical: 'top',
  },
  actions: {
    flexDirection: 'row',
    padding: Spacing.four,
    borderTopWidth: 1,
    gap: Spacing.three,
  },
  cancelBtn: {
    flex: 1,
    height: 48,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  submitBtn: {
    flex: 1.5,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 16,
  },

  // Calendar Picker Styles
  calendarContainer: {
    borderWidth: 1.5,
    borderRadius: 16,
    padding: Spacing.three,
    marginTop: Spacing.one,
    marginBottom: Spacing.three,
  },
  calendarHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.one,
    paddingHorizontal: Spacing.two,
    marginBottom: Spacing.three,
  },
  calendarMonthText: {
    fontSize: 15,
    fontWeight: 'bold',
  },
  monthNavBtn: {
    padding: Spacing.one,
  },
  weekdaysRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: Spacing.two,
  },
  weekdayText: {
    width: '14.28%',
    textAlign: 'center',
    fontSize: 11,
    fontWeight: 'bold',
  },
  daysGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  dayCell: {
    width: '14.28%',
    aspectRatio: 1,
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 2,
  },
  dayCellText: {
    fontSize: 13,
  },
  selectedDayCell: {
    borderRadius: 18,
  },
  selectedDayCellText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  genderPreferenceRow: {
    flexDirection: 'row',
    gap: Spacing.two,
    marginTop: Spacing.one,
    flexWrap: 'wrap',
    width: '100%',
  },
  genderPreferenceBtn: {
    flex: 1,
    minWidth: 90,
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.two,
  },
  genderPreferenceText: {
    fontSize: 12,
    fontWeight: '600',
  },
});
