import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../widgets/ride_card.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final provider = context.watch<RidesProvider>();
    final user = provider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No active profile session.')),
      );
    }

    final myRides = provider.rides.where((r) => r.poster.email == user.email).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('My Profile & Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => provider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(user.photo),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('+91 ${user.phone}', style: TextStyle(color: textSecondary, fontSize: 13)),
                        Text(user.email, style: TextStyle(color: textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(user.gender, style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Text('My Offered Rides (${myRides.length})', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            if (myRides.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.directions_car_outlined, size: 48, color: textSecondary),
                    const SizedBox(height: 8),
                    Text('You have not offered any rides yet.', style: TextStyle(color: textSecondary)),
                  ],
                ),
              )
            else
              ...myRides.map((ride) => RideCard(ride: ride)),
          ],
        ),
      ),
    );
  }
}
