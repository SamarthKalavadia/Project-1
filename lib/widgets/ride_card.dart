import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../models/ride_request.dart';
import '../providers/rides_provider.dart';
import '../theme/app_theme.dart';
import 'contact_reveal_button.dart';

class RideCard extends StatelessWidget {
  final Ride ride;

  const RideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(ride.poster.photo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ride.poster.name,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ride.poster.gender,
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Departure: ${ride.departureTime}',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Status / Seats left badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ride.status,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ride.seatsLeft} / ${ride.seatsTotal} seats open',
                    style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: border),
          const SizedBox(height: 14),

          // Route Details
          Row(
            children: [
              Icon(Icons.my_location, size: 18, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.pickup,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            height: 14,
            width: 2,
            color: primary.withOpacity(0.3),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.destination,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fare & Gender Preference
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fare Share: ${ride.fareEstimate}',
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              if (ride.genderPreference != 'Both')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ride.genderPreference,
                    style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold),
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

          // Action Section
          if (isOwner) ...[
            Divider(height: 1, color: border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Incoming Requests (${ride.requests.length})', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                if (ride.status == 'Pending')
                  TextButton(
                    onPressed: () => provider.cancelRide(ride.id),
                    child: const Text('Cancel Ride', style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                else if (ride.status == 'Accepted')
                  TextButton(
                    onPressed: () => provider.completeRide(ride.id),
                    child: Text('Complete Ride', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (ride.requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('No requests received yet', style: TextStyle(color: textSecondary, fontSize: 12)),
              )
            else
              ...ride.requests.map((RideRequest req) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundImage: NetworkImage(req.user.photo)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req.user.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('+91 ${req.user.phone}', style: TextStyle(color: textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (req.status == 'Pending') ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          onPressed: () => provider.acceptRequest(ride.id, req.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                          onPressed: () => provider.declineRequest(ride.id, req.id),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: req.status == 'Accepted' ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status,
                            style: TextStyle(
                              color: req.status == 'Accepted' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ] else if (isAcceptor) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                      child: Text('Requested (Pending Host Review)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => provider.cancelRequest(ride.id, currentUser.email),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: ride.seatsLeft > 0 ? () => provider.requestToJoin(ride.id) : null,
                child: Text(
                  ride.seatsLeft > 0 ? 'Request to Join Ride' : 'Ride Full',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
