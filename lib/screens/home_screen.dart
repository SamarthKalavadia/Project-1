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
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final provider = context.watch<RidesProvider>();
    final rides = provider.rides;
    final filters = provider.filters;

    // Apply active filters
    final filteredRides = rides.where((ride) {
      if (filters.pickup.isNotEmpty && !ride.pickup.toLowerCase().contains(filters.pickup.toLowerCase())) {
        return false;
      }
      if (filters.destination.isNotEmpty && !ride.destination.toLowerCase().contains(filters.destination.toLowerCase())) {
        return false;
      }
      if (filters.seats != null && ride.seatsLeft < filters.seats!) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_car, color: primary, size: 28),
            const SizedBox(width: 8),
            Text('AutoShare', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar / Active Filter Chips
            if (filters.pickup.isNotEmpty || filters.destination.isNotEmpty || filters.seats != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: primary.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: Colors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Active Filters Applied',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.clearFilters(),
                      child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Main List
            Expanded(
              child: filteredRides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: textSecondary),
                          const SizedBox(height: 12),
                          Text('No rides match your search criteria', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Try adjusting your filters or post a new ride offer', style: TextStyle(color: textSecondary, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRides.length,
                      itemBuilder: (context, index) {
                        return RideCard(ride: filteredRides[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const PostRideModal(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Offer Ride', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
