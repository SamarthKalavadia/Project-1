import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../widgets/ride_card.dart';
import '../widgets/filter_modal.dart';
import '../widgets/post_ride_modal.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final provider = context.watch<RidesProvider>();
    final rides = provider.rides;
    final filters = provider.filters;

    final currentUser = provider.currentUser;

    // Filter rides based on search criteria & strict gender preferences
    final filteredRides = rides.where((ride) {
      final isOwner = currentUser != null && (currentUser.email == ride.poster.email || currentUser.phone == ride.poster.phone);

      // 1. Strict Gender Ineligibility Filtering:
      // Male users MUST NOT see "Girls only" rides (unless owner)
      // Female users MUST NOT see "Boys only" rides (unless owner)
      if (currentUser != null && !isOwner) {
        final isMale = currentUser.gender.toLowerCase() == 'male';
        final isFemale = currentUser.gender.toLowerCase() == 'female';

        if (isMale && ride.genderPreference == 'Girls only') {
          return false;
        }
        if (isFemale && ride.genderPreference == 'Boys only') {
          return false;
        }
      }

      // 2. Search location & filter criteria
      if (filters.pickup.isNotEmpty && !ride.pickup.toLowerCase().contains(filters.pickup.toLowerCase())) {
        return false;
      }
      if (filters.destination.isNotEmpty && !ride.destination.toLowerCase().contains(filters.destination.toLowerCase())) {
        return false;
      }
      if (filters.seats != null && ride.seatsLeft < filters.seats!) {
        return false;
      }
      if (filters.genderPreference != 'all' && filters.genderPreference != 'Both') {
        if (ride.genderPreference != 'Both' && ride.genderPreference != filters.genderPreference) {
          return false;
        }
      }
      return true;
    }).toList();

    final hasActiveFilters = filters.pickup.isNotEmpty ||
        filters.destination.isNotEmpty ||
        filters.seats != null ||
        (filters.genderPreference != 'all' && filters.genderPreference != 'Both');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_car, color: primary, size: 28),
            const SizedBox(width: 8),
            Text('AutoShare', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'BETA',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const FilterModal(),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Filters Bar
              if (hasActiveFilters)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Active Filters Applied',
                          style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => provider.clearFilters(),
                        child: Text(
                          'Clear All',
                          style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Welcome Block
              Text('Find a Cab/Auto Pool', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                'Join co-passengers heading your way and split costs',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Feed list
              if (filteredRides.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.search_off, size: 36, color: primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No matching ride requests',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try clearing some filters, searching for a broader location, or post your own ride request to get joined!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => provider.clearFilters(),
                        child: const Text('Clear All Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else
                ...filteredRides.map((ride) => RideCard(ride: ride)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const PostRideModal(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
