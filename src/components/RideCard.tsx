import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Image, Modal, Text, ActivityIndicator, Linking } from 'react-native';
import { Feather, Ionicons } from '@expo/vector-icons';
import { Ride, useRides } from '@/context/RidesContext';
import { ThemedText } from './themed-text';
import { ThemedView } from './themed-view';
import { ContactRevealButton } from './ContactRevealButton';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

interface RideCardProps {
  ride: Ride;
  onAccept: (rideId: string) => void;
  onCancel?: (rideId: string) => void;
  onComplete?: (rideId: string) => void;
  onAcceptRequest?: (rideId: string, requestId: string) => void;
  onDeclineRequest?: (rideId: string, requestId: string) => void;
  onCancelRequest?: (rideId: string, email: string) => void;
}

export const RideCard: React.FC<RideCardProps> = ({
  ride,
  onAccept,
  onCancel,
  onComplete,
  onAcceptRequest,
  onDeclineRequest,
  onCancelRequest
}) => {
  const theme = useTheme();
  const { currentUser } = useRides();
  const [confirmVisible, setConfirmVisible] = useState(false);
  const [contactVisible, setContactVisible] = useState(false);
  const [loading, setLoading] = useState(false);

  if (!currentUser) return null;

  const isOwner = ride.poster.email === currentUser.email;
  const isJoined = ride.acceptor?.email === currentUser.email;
  const pendingRequestsCount = ride.requests?.filter(r => r.status === 'Pending').length || 0;

  const handleJoinPress = () => {
    setConfirmVisible(true);
  };

  const handleConfirmAccept = () => {
    setLoading(true);
    // Simulate minor network delay for micro-animation feel
    setTimeout(() => {
      onAccept(ride.id);
      setLoading(false);
      setConfirmVisible(false);
    }, 800);
  };

  const getStatusColor = () => {
    switch (ride.status) {
      case 'Pending':
        return theme.primary;
      case 'Accepted':
        return theme.success;
      case 'Completed':
        return theme.textSecondary;
      case 'Cancelled':
        return theme.danger;
      default:
        return theme.textSecondary;
    }
  };

  const isGenderAllowed = (() => {
    if (!ride.genderPreference || ride.genderPreference === 'Both') return true;
    if (ride.genderPreference === 'Boys only') return currentUser.gender === 'Male';
    if (ride.genderPreference === 'Girls only') return currentUser.gender === 'Female';
    return true;
  })();

  const getGenderPreferenceColor = () => {
    switch (ride.genderPreference) {
      case 'Boys only':
        return '#0284C7';
      case 'Girls only':
        return '#DB2777';
      default:
        return theme.primary;
    }
  };

  const getGenderPreferenceLabel = () => {
    switch (ride.genderPreference) {
      case 'Boys only':
        return '🙋‍♂️ Boys only';
      case 'Girls only':
        return '🙋‍♀️ Girls only';
      default:
        return '👥 Co-ed';
    }
  };

  return (
    <ThemedView type="backgroundElement" style={[styles.card, { borderColor: theme.border }]}>
      {/* Top Header: Poster Info & Status Badge */}
      <View style={styles.header}>
        <View style={styles.posterContainer}>
          <Image
            source={{ uri: ride.poster.photo }}
            style={styles.avatar}
          />
          <View>
            <ThemedText type="smallBold">{ride.poster.name}</ThemedText>
            <ThemedText type="code" themeColor="textSecondary" style={styles.roleText}>
              {isOwner ? 'You posted' : 'Host'}
            </ThemedText>
          </View>
        </View>

        <View style={{ flexDirection: 'row', alignItems: 'center', gap: Spacing.two }}>
          {ride.genderPreference && (
            <View style={[styles.statusBadge, { backgroundColor: getGenderPreferenceColor() + '15' }]}>
              <Text style={[styles.statusText, { color: getGenderPreferenceColor() }]}>
                {getGenderPreferenceLabel()}
              </Text>
            </View>
          )}
          {pendingRequestsCount > 0 && (
            <View style={[styles.requestsCountBadge, { backgroundColor: theme.primary + '15', borderColor: theme.primary + '30' }]}>
              <Text style={[styles.requestsCountText, { color: theme.primary }]}>
                {pendingRequestsCount} {pendingRequestsCount === 1 ? 'request' : 'requests'}
              </Text>
            </View>
          )}
          <View style={[styles.statusBadge, { backgroundColor: getStatusColor() + '15' }]}>
            <Text style={[styles.statusText, { color: getStatusColor() }]}>
              {ride.status}
            </Text>
          </View>
        </View>
      </View>

      {/* Divider */}
      <View style={[styles.divider, { backgroundColor: theme.border }]} />

      {/* Route Info: Pickup -> Destination */}
      <View style={styles.routeContainer}>
        <View style={styles.routeIndicator}>
          <View style={[styles.dot, { backgroundColor: theme.primary }]} />
          <View style={[styles.line, { borderColor: theme.border }]} />
          <Ionicons name="location" size={16} color={theme.danger} />
        </View>

        <View style={styles.routeAddresses}>
          <View style={styles.addressBlock}>
            <ThemedText type="smallBold" themeColor="textSecondary" style={styles.addressLabel}>PICKUP</ThemedText>
            <ThemedText type="default" style={styles.addressText} numberOfLines={1}>
              {ride.pickup}
            </ThemedText>
          </View>

          <View style={styles.addressBlock}>
            <ThemedText type="smallBold" themeColor="textSecondary" style={styles.addressLabel}>DESTINATION</ThemedText>
            <ThemedText type="default" style={styles.addressText} numberOfLines={1}>
              {ride.destination}
            </ThemedText>
          </View>
        </View>
      </View>

      {/* Ride Specs: Time, Seats, Fare */}
      <View style={[styles.specsRow, { backgroundColor: theme.background }]}>
        <View style={styles.specItem}>
          <Feather name="clock" size={14} color={theme.primary} />
          <ThemedText type="small" style={styles.specText}>{ride.departureTime}</ThemedText>
        </View>

        <View style={styles.specItem}>
          <Feather name="users" size={14} color={theme.primary} />
          <ThemedText type="small" style={[
            styles.specText,
            ride.seatsLeft === 0 ? { color: theme.danger } : null,
            (ride.seatsLeft > 0 && ride.seatsLeft <= 1) ? { color: theme.warning } : null
          ]}>
            {ride.seatsLeft === 0 ? 'Full' : `${ride.seatsLeft}/${ride.seatsTotal} left`}
          </ThemedText>
        </View>

        <View style={styles.specItem}>
          <Ionicons name="card-outline" size={14} color={theme.primary} />
          <ThemedText type="small" style={styles.specText}>{ride.fareEstimate}</ThemedText>
        </View>
      </View>

      {/* Optional Notes */}
      {ride.notes ? (
        <View style={[styles.notesContainer, { borderLeftColor: theme.primary }]}>
          <ThemedText type="small" themeColor="textSecondary" style={styles.notesText} numberOfLines={2}>
            &ldquo;{ride.notes}&rdquo;
          </ThemedText>
        </View>
      ) : null}

      {/* Bottom Actions based on Status & Role */}
      <View style={styles.actionContainer}>
        {ride.status === 'Pending' && !isOwner && (() => {
          const myRequest = ride.requests?.find(r => r.user.email === currentUser.email);
          if (myRequest) {
            if (myRequest.status === 'Pending') {
              return (
                <View style={styles.requestedButtonGroup}>
                  <View style={[styles.requestStatusBadgeBox, { backgroundColor: theme.backgroundSelected, borderColor: theme.border }]}>
                    <Feather name="clock" size={14} color={theme.primary} style={{ marginRight: 6 }} />
                    <Text style={[styles.requestStatusBadgeText, { color: theme.primary }]}>Requested (Pending)</Text>
                  </View>
                  <Pressable
                    style={({ pressed }) => [
                      styles.cancelRequestButton,
                      { borderColor: theme.danger, backgroundColor: theme.background },
                      pressed && { backgroundColor: theme.danger + '10' }
                    ]}
                    onPress={() => {
                      if (onCancelRequest) onCancelRequest(ride.id, currentUser.email);
                    }}
                  >
                    <Feather name="x-circle" size={14} color={theme.danger} style={{ marginRight: 4 }} />
                    <Text style={[styles.cancelRequestText, { color: theme.danger }]}>Cancel</Text>
                  </Pressable>
                </View>
              );
            }
            if (myRequest.status === 'Declined') {
              return (
                <Pressable
                  style={[styles.primaryButton, { backgroundColor: theme.backgroundSelected, width: '100%' }]}
                  disabled={true}
                >
                  <Feather name="x-circle" size={16} color={theme.danger} style={{ marginRight: 6 }} />
                  <Text style={[styles.buttonText, { color: theme.danger }]}>Request Declined</Text>
                </Pressable>
              );
            }
          }

          if (!isGenderAllowed) {
            return (
              <Pressable
                style={[styles.primaryButton, { backgroundColor: theme.border, opacity: 0.6 }]}
                disabled={true}
              >
                <Feather name="lock" size={16} color={theme.textSecondary} style={{ marginRight: 6 }} />
                <Text style={[styles.buttonText, { color: theme.textSecondary }]}>
                  {ride.genderPreference === 'Boys only' ? 'Boys Only Ride' : 'Girls Only Ride'}
                </Text>
              </Pressable>
            );
          }

          return (
            <Pressable
              style={[styles.primaryButton, { backgroundColor: theme.primary }]}
              onPress={handleJoinPress}
              android_ripple={{ color: theme.primaryLight }}
            >
              <Feather name="plus-circle" size={16} color="#FFFFFF" style={{ marginRight: 6 }} />
              <Text style={styles.buttonText}>Book / Join Ride</Text>
            </Pressable>
          );
        })()}

        {ride.status === 'Pending' && isOwner && (
          <View style={styles.ownerActionsContainer}>
            {ride.requests && ride.requests.length > 0 ? (
              <View style={styles.requestsSection}>
                <ThemedText type="smallBold" themeColor="textSecondary" style={styles.requestsTitle}>
                  BOOKING REQUESTS
                </ThemedText>
                {ride.requests.map((req) => (
                  <View key={req.id} style={[styles.requestRow, { borderColor: theme.border, backgroundColor: theme.background }]}>
                    <View style={styles.requestUserGroup}>
                      <Image source={{ uri: req.user.photo }} style={styles.requestAvatar} />
                      <View>
                        <ThemedText type="smallBold">{req.user.name}</ThemedText>
                        <ThemedText type="code" themeColor="textSecondary" style={{ fontSize: 10 }}>{req.user.gender}</ThemedText>
                      </View>
                    </View>

                    {req.status === 'Pending' ? (
                      <View style={styles.requestBtnGroup}>
                        <Pressable
                          style={[styles.reqDeclineBtn, { borderColor: theme.danger }]}
                          onPress={() => {
                            if (onDeclineRequest) onDeclineRequest(ride.id, req.id);
                          }}
                        >
                          <Feather name="x" size={14} color={theme.danger} />
                        </Pressable>
                        <Pressable
                          style={[styles.reqAcceptBtn, { backgroundColor: theme.primary }]}
                          onPress={() => {
                            if (onAcceptRequest) onAcceptRequest(ride.id, req.id);
                          }}
                        >
                          <Feather name="check" size={14} color="#FFFFFF" />
                        </Pressable>
                      </View>
                    ) : (
                      <Text style={[
                        styles.reqStatusText,
                        { color: req.status === 'Accepted' ? theme.success : theme.danger }
                      ]}>
                        {req.status}
                      </Text>
                    )}
                  </View>
                ))}
              </View>
            ) : (
              <ThemedText type="small" themeColor="textSecondary" style={styles.ownerStatusText}>
                Waiting for passengers to book...
              </ThemedText>
            )}

            {onCancel && (
              <Pressable
                style={[styles.dangerButton, { borderColor: theme.danger, marginTop: Spacing.two }]}
                onPress={() => onCancel(ride.id)}
              >
                <Text style={[styles.dangerButtonText, { color: theme.danger }]}>Cancel Ride</Text>
              </Pressable>
            )}
          </View>
        )}

        {ride.status === 'Accepted' && (isOwner || isJoined) && (
          <View style={styles.acceptedRow}>
            {/* View Details takes flex space */}
            <Pressable
              style={[styles.primaryButton, { backgroundColor: theme.primary }]}
              onPress={() => setContactVisible(true)}
            >
              <Feather name="user" size={16} color="#FFFFFF" style={{ marginRight: 6 }} />
              <Text style={styles.buttonText}>
                {isOwner ? 'View Passenger' : 'View Host'}
              </Text>
            </Pressable>

            {/* Direct Call — fixed square icon button */}
            {(() => {
              const targetUser = isOwner ? ride.acceptor : ride.poster;
              if (!targetUser || !targetUser.phone) return null;

              return (
                <Pressable
                  style={({ pressed }) => [
                    styles.directCallButton,
                    { backgroundColor: theme.success },
                    pressed && { opacity: 0.9, transform: [{ scale: 0.96 }] }
                  ]}
                  onPress={() => {
                    Linking.openURL(`tel:${targetUser.phone}`).catch(() => {});
                  }}
                >
                  <Feather name="phone-call" size={16} color="#FFFFFF" />
                </Pressable>
              );
            })()}

            {/* Leave Pool — only shown to passenger, takes flex space */}
            {!isOwner && (
              <Pressable
                style={({ pressed }) => [
                  styles.cancelBookingButton,
                  { borderColor: theme.danger, backgroundColor: theme.background },
                  pressed && { backgroundColor: theme.danger + '10' }
                ]}
                onPress={() => {
                  if (onCancelRequest) onCancelRequest(ride.id, currentUser.email);
                }}
              >
                <Feather name="log-out" size={14} color={theme.danger} style={{ marginRight: 4 }} />
                <Text style={[styles.cancelBookingText, { color: theme.danger }]}>Leave Pool</Text>
              </Pressable>
            )}
          </View>
        )}

        {ride.status === 'Accepted' && !isOwner && !isJoined && (
          <View style={[styles.secondaryInfoBox, { backgroundColor: theme.background }]}>
            <Feather name="lock" size={14} color={theme.textSecondary} style={{ marginRight: 6 }} />
            <ThemedText type="small" themeColor="textSecondary">
              Ride has been booked by another user.
            </ThemedText>
          </View>
        )}

        {ride.status === 'Completed' && (
          <View style={[styles.secondaryInfoBox, { backgroundColor: theme.background }]}>
            <Ionicons name="checkmark-done" size={14} color={theme.success} style={{ marginRight: 6 }} />
            <ThemedText type="small" themeColor="textSecondary">
              This ride was successfully completed.
            </ThemedText>
          </View>
        )}

        {ride.status === 'Cancelled' && (
          <View style={[styles.secondaryInfoBox, { backgroundColor: theme.background }]}>
            <Feather name="x-circle" size={14} color={theme.danger} style={{ marginRight: 6 }} />
            <ThemedText type="small" themeColor="danger">
              This ride request was cancelled.
            </ThemedText>
          </View>
        )}
      </View>

      {/* JOIN CONFIRMATION MODAL */}
      <Modal
        animationType="fade"
        transparent={true}
        visible={confirmVisible}
        onRequestClose={() => setConfirmVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <ThemedView type="backgroundElement" style={styles.modalContainer}>
            <View style={[styles.modalIconContainer, { backgroundColor: theme.primary + '15' }]}>
              <Feather name="help-circle" size={28} color={theme.primary} />
            </View>

            <ThemedText type="subtitle" style={styles.modalTitle}>Join Ride Pool?</ThemedText>
            <ThemedText type="default" themeColor="textSecondary" style={styles.modalDesc}>
              You are joining {ride.poster.name}&apos;s ride from <ThemedText type="smallBold">{ride.pickup}</ThemedText> to <ThemedText type="smallBold">{ride.destination}</ThemedText>.
            </ThemedText>

            <View style={[styles.miniSummary, { backgroundColor: theme.background }]}>
              <View style={styles.miniItem}>
                <Feather name="clock" size={14} color={theme.textSecondary} />
                <ThemedText type="small" style={{ marginLeft: 4 }}>{ride.departureTime}</ThemedText>
              </View>
              <View style={styles.miniItem}>
                <Ionicons name="card-outline" size={14} color={theme.textSecondary} />
                <ThemedText type="small" style={{ marginLeft: 4 }}>{ride.fareEstimate}</ThemedText>
              </View>
            </View>

            <View style={styles.modalButtons}>
              <Pressable
                style={[styles.modalCancelBtn, { borderColor: theme.border }]}
                onPress={() => setConfirmVisible(false)}
                disabled={loading}
              >
                <ThemedText type="smallBold" themeColor="textSecondary">Cancel</ThemedText>
              </Pressable>

              <Pressable
                style={[styles.modalConfirmBtn, { backgroundColor: theme.primary }]}
                onPress={handleConfirmAccept}
                disabled={loading}
              >
                {loading ? (
                  <ActivityIndicator color="#FFFFFF" size="small" />
                ) : (
                  <Text style={styles.modalConfirmText}>Accept & Join</Text>
                )}
              </Pressable>
            </View>
          </ThemedView>
        </View>
      </Modal>

      {/* CONTACT INFO MODAL */}
      <Modal
        animationType="slide"
        transparent={true}
        visible={contactVisible}
        onRequestClose={() => setContactVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <ThemedView type="backgroundElement" style={[styles.modalContainer, styles.bottomSheet]}>
            <View style={[styles.modalHandle, { backgroundColor: theme.border }]} />

            <View style={styles.contactHeader}>
              <ThemedText type="subtitle" style={{ fontSize: 22 }}>
                {isOwner ? 'Passenger Details' : 'Host Details'}
              </ThemedText>
              <Pressable onPress={() => setContactVisible(false)}>
                <Feather name="x" size={20} color={theme.text} />
              </Pressable>
            </View>

            {/* Profile Detail */}
            {(() => {
              const displayUser = isOwner ? ride.acceptor : ride.poster;
              if (!displayUser) return null;

              return (
                <View style={styles.contactContent}>
                  <View style={styles.contactProfileRow}>
                    <Image source={{ uri: displayUser.photo }} style={styles.largeAvatar} />
                    <View>
                      <ThemedText type="subtitle" style={{ fontSize: 20 }}>{displayUser.name}</ThemedText>
                      <ThemedText type="small" themeColor="textSecondary">
                        {isOwner ? 'Joined passenger' : 'Ride Coordinator'}
                      </ThemedText>
                    </View>
                  </View>

                  <ContactRevealButton
                    userName={displayUser.name}
                    phone={displayUser.phone}
                    email={displayUser.email}
                  />


                </View>
              );
            })()}
          </ThemedView>
        </View>
      </Modal>
    </ThemedView>
  );
};

const styles = StyleSheet.create({
  card: {
    borderRadius: 16,
    padding: Spacing.three,
    marginBottom: Spacing.three,
    borderWidth: 1.5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  posterContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
  },
  avatar: {
    width: 38,
    height: 38,
    borderRadius: 19,
  },
  roleText: {
    fontSize: 10,
    marginTop: -2,
  },
  statusBadge: {
    paddingVertical: Spacing.half,
    paddingHorizontal: Spacing.two,
    borderRadius: 12,
  },
  statusText: {
    fontSize: 11,
    fontWeight: 'bold',
  },
  divider: {
    height: 1,
    marginVertical: Spacing.two,
  },
  routeContainer: {
    flexDirection: 'row',
    marginVertical: Spacing.one,
    paddingHorizontal: Spacing.one,
  },
  routeIndicator: {
    width: 20,
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 6,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  line: {
    flex: 1,
    width: 0,
    borderWidth: 1,
    borderStyle: 'dashed',
    marginVertical: 4,
  },
  routeAddresses: {
    flex: 1,
    marginLeft: Spacing.two,
    gap: Spacing.two,
  },
  addressBlock: {
    justifyContent: 'center',
  },
  addressLabel: {
    fontSize: 9,
    letterSpacing: 0.5,
  },
  addressText: {
    fontSize: 15,
    marginTop: 1,
  },
  specsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: Spacing.two,
    borderRadius: 12,
    marginTop: Spacing.three,
  },
  specItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.one,
  },
  specText: {
    fontSize: 13,
  },
  notesContainer: {
    borderLeftWidth: 3,
    paddingLeft: Spacing.two,
    marginTop: Spacing.three,
  },
  notesText: {
    fontSize: 13,
    fontStyle: 'italic',
  },
  actionContainer: {
    marginTop: Spacing.three,
  },
  primaryButton: {
    flexDirection: 'row',
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#0D9488',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
    flex: 1,
    paddingHorizontal: Spacing.two,
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 14,
  },
  ownerActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
  },
  ownerStatusText: {
    fontSize: 13,
  },
  dangerButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1.5,
  },
  dangerButtonText: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  completeButton: {
    flexDirection: 'row',
    height: 40,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
  },
  acceptedRow: {
    flexDirection: 'row',
    gap: Spacing.two,
    alignItems: 'stretch',
    width: '100%',
  },
  secondaryButton: {
    flexDirection: 'row',
    height: 44,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    flex: 1,
  },
  secondaryButtonText: {
    fontWeight: 'bold',
    fontSize: 14,
  },
  secondaryInfoBox: {
    flexDirection: 'row',
    padding: Spacing.two,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.four,
  },
  modalContainer: {
    width: '100%',
    maxWidth: 340,
    borderRadius: 24,
    padding: Spacing.four,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.15,
    shadowRadius: 20,
    elevation: 10,
  },
  bottomSheet: {
    maxWidth: 500,
    borderRadius: 0,
    borderTopLeftRadius: 30,
    borderTopRightRadius: 30,
    position: 'absolute',
    bottom: 0,
    paddingBottom: Spacing.five,
  },
  modalHandle: {
    width: 40,
    height: 5,
    borderRadius: 2.5,
    marginBottom: Spacing.three,
  },
  modalIconContainer: {
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.three,
  },
  modalTitle: {
    fontSize: 20,
    textAlign: 'center',
    marginBottom: Spacing.two,
  },
  modalDesc: {
    textAlign: 'center',
    fontSize: 14,
    lineHeight: 20,
    marginBottom: Spacing.three,
  },
  miniSummary: {
    flexDirection: 'row',
    gap: Spacing.three,
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.three,
    borderRadius: 12,
    marginBottom: Spacing.four,
    width: '100%',
    justifyContent: 'center',
  },
  miniItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  modalButtons: {
    flexDirection: 'row',
    gap: Spacing.two,
    width: '100%',
  },
  modalCancelBtn: {
    flex: 1,
    height: 44,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalConfirmBtn: {
    flex: 1.5,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalConfirmText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  contactHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    marginBottom: Spacing.four,
  },
  contactContent: {
    width: '100%',
    alignItems: 'center',
  },
  contactProfileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.three,
    alignSelf: 'flex-start',
    marginBottom: Spacing.four,
  },
  largeAvatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
  },
  contactCard: {
    width: '100%',
    borderRadius: 16,
    padding: Spacing.three,
    gap: Spacing.three,
  },
  contactRowItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.three,
  },
  contactInfoTexts: {
    gap: 1,
  },
  contactCardDivider: {
    height: 1,
  },
  ownerActionsContainer: {
    width: '100%',
    gap: Spacing.two,
  },
  requestsSection: {
    width: '100%',
    gap: Spacing.one,
    marginVertical: Spacing.two,
  },
  requestsTitle: {
    fontSize: 10,
    letterSpacing: 0.5,
    marginBottom: Spacing.one,
  },
  requestRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.two,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: Spacing.one,
  },
  requestUserGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
  },
  requestAvatar: {
    width: 28,
    height: 28,
    borderRadius: 14,
  },
  requestBtnGroup: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  reqDeclineBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reqAcceptBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reqStatusText: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  requestsCountBadge: {
    paddingVertical: Spacing.half,
    paddingHorizontal: Spacing.two,
    borderRadius: 8,
    borderWidth: 1,
  },
  requestsCountText: {
    fontSize: 10,
    fontWeight: 'bold',
  },
  requestedButtonGroup: {
    width: '100%',
    flexDirection: 'row',
    gap: Spacing.two,
    alignItems: 'center',
  },
  requestStatusBadgeBox: {
    flex: 1.5,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 44,
    borderRadius: 12,
    borderWidth: 1,
  },
  requestStatusBadgeText: {
    fontSize: 13,
    fontWeight: '600',
  },
  cancelRequestButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 44,
    borderRadius: 12,
    borderWidth: 1.5,
  },
  cancelRequestText: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  cancelBookingButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 44,
    borderRadius: 12,
    borderWidth: 1.5,
  },
  cancelBookingText: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  directCallButton: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
