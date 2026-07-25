import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../providers/rides_provider.dart';
import '../theme/app_theme.dart';
import 'contact_reveal_button.dart';
import 'user_avatar.dart';

class RideCard extends StatefulWidget {
  final Ride ride;

  const RideCard({super.key, required this.ride});

  @override
  State<RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<RideCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final provider = context.watch<RidesProvider>();
    final currentUser = provider.currentUser;

    final isOwner = currentUser != null && (currentUser.email == ride.poster.email || currentUser.phone == ride.poster.phone);
    final isAcceptor = currentUser != null && ride.acceptor != null && (ride.acceptor!.email == currentUser.email || ride.acceptor!.phone == currentUser.phone);
    final hasRequested = currentUser != null && ride.requests.any((r) => r.user.email == currentUser.email || r.user.phone == currentUser.phone);

    Color statusBgColor = Colors.amber.withOpacity(0.15);
    Color statusTextColor = Colors.amber;
    if (ride.status == 'Accepted') {
      statusBgColor = Colors.green.withOpacity(0.15);
      statusTextColor = Colors.green;
    } else if (ride.status == 'Completed') {
      statusBgColor = primary.withOpacity(0.15);
      statusTextColor = primary;
    } else if (ride.status == 'Cancelled') {
      statusBgColor = Colors.red.withOpacity(0.15);
      statusTextColor = Colors.red;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.08 : 0.04),
                blurRadius: _isPressed ? 6 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Poster Info & Badges
              Row(
                children: [
                  UserAvatar(
                    radius: 22,
                    photoUrl: ride.poster.photo,
                    name: ride.poster.name,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ride.poster.name,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride.poster.gender} • +91 ${ride.poster.phone}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ride.status,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pickup & Destination Route Visualizer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, color: primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ride.pickup,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 14,
                            color: primary.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ride.destination,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Time, Seats Left, Fare & Gender Badges
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ride.departureTime,
                            style: TextStyle(color: textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.event_seat, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.seatsLeft}/${ride.seatsTotal} seats',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Est. Fare: ${ride.fareEstimate}',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Pref: ${ride.genderPreference}',
                      style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              if (ride.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Note: "${ride.notes}"',
                  style: TextStyle(color: textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 14),

              // Action Buttons / Request Status Handling
              if (isOwner) ...[
                if (ride.requests.isNotEmpty) ...[
                  Text(
                    'Join Requests (${ride.requests.length}):',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: ride.requests.map((req) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(photoUrl: req.user.photo, name: req.user.name, radius: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req.user.name,
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            if (req.status == 'Pending') ...[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  provider.acceptRequest(ride.id, req.id);
                                },
                                child: const Text('Accept', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  provider.declineRequest(ride.id, req.id);
                                },
                                child: const Text('Decline', style: TextStyle(fontSize: 11)),
                              ),
                            ] else ...[
                              Text(
                                req.status,
                                style: TextStyle(
                                  color: req.status == 'Accepted' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (ride.status == 'Pending' || ride.status == 'Accepted') ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => provider.cancelRide(ride.id),
                          child: const Text('Cancel Ride', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => provider.completeRide(ride.id),
                          child: const Text('Complete Ride', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (isAcceptor) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Request Accepted! You are in.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      ContactRevealButton(phoneNumber: ride.poster.phone),
                    ],
                  ),
                ),
              ] else if (hasRequested) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Request Pending Host Approval',
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        if (currentUser != null) {
                          provider.cancelRequest(ride.id, currentUser.email);
                        }
                      },
                      tooltip: 'Cancel Request',
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: ride.seatsLeft <= 0 || ride.status != 'Pending'
                        ? null
                        : () {
                            if (currentUser != null) {
                              provider.requestToJoin(ride.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ride request sent to host!')),
                              );
                            }
                          },
                    icon: const Icon(Icons.hail, size: 18),
                    label: Text(
                      ride.seatsLeft <= 0 ? 'Full Seats' : 'Request to Join Ride',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
