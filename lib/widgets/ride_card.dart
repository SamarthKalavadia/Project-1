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

    final isOwner = currentUser != null && currentUser.email == ride.poster.email;
    final isAcceptor = currentUser != null && ride.acceptor != null && ride.acceptor!.email == currentUser.email;
    final hasRequested = currentUser != null && ride.requests.any((r) => r.user.email == currentUser.email);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
                radius: 20,
                backgroundImage: NetworkImage(ride.poster.photo),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.poster.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Departure: ${ride.departureTime}',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FittedBox(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${ride.seatsLeft} / ${ride.seatsTotal} Left',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Route Details
          Row(
            children: [
              Icon(Icons.my_location, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.pickup,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            height: 16,
            width: 2,
            color: primary.withOpacity(0.3),
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.destination,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notes & Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fare Share: ${ride.fareEstimate}',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (ride.genderPreference != 'Both')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ride.genderPreference,
                    style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (ride.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ride.notes,
              style: TextStyle(color: textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 14),

          // Actions / Status
          if (isOwner) ...[
            Text('Ride Requests (${ride.requests.length})', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (ride.requests.isEmpty)
              Text('No requests yet', style: TextStyle(color: textSecondary, fontSize: 12))
            else
              ...ride.requests.map((RideRequest req) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackgroundSelected : AppColors.lightBackgroundSelected,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundImage: NetworkImage(req.user.photo)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(req.user.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      ),
                      if (req.status == 'Pending') ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                          onPressed: () => provider.acceptRequest(ride.id, req.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                          onPressed: () => provider.declineRequest(ride.id, req.id),
                        ),
                      ] else
                        Text(req.status, style: TextStyle(color: req.status == 'Accepted' ? Colors.green : Colors.red)),
                    ],
                  ),
                );
              }),
          ] else if (isAcceptor) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 6),
                const Text('Request Accepted!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const Spacer(),
                ContactRevealButton(phoneNumber: ride.poster.phone),
              ],
            ),
          ] else if (hasRequested) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Requested to Join (Pending)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: ride.seatsLeft > 0 ? () => provider.requestToJoin(ride.id) : null,
                child: Text(ride.seatsLeft > 0 ? 'Request to Join Ride' : 'Ride Full'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
