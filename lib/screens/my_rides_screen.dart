import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../widgets/ride_card.dart';
import '../theme/app_theme.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  String _activeTab = 'posted'; // 'posted' | 'accepted'

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
    final currentUser = provider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: Text('Please sign in to view your rides.')),
      );
    }

    final postedRides = provider.rides.where((r) => r.poster.email == currentUser.email).toList();
    final acceptedRides = provider.rides.where((r) => r.acceptor?.email == currentUser.email).toList();
    final activeList = _activeTab == 'posted' ? postedRides : acceptedRides;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('My Rides', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description
            Text('Manage and coordinate your carpools', style: TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 16),

            // Segmented Tab Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'posted'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 'posted' ? primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              size: 14,
                              color: _activeTab == 'posted' ? Colors.white : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Posted by me (${postedRides.length})',
                              style: TextStyle(
                                color: _activeTab == 'posted' ? Colors.white : textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'accepted'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 'accepted' ? primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_box,
                              size: 14,
                              color: _activeTab == 'accepted' ? Colors.white : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Joined (${acceptedRides.length})',
                              style: TextStyle(
                                color: _activeTab == 'accepted' ? Colors.white : textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rides List / Empty State
            if (activeList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border, style: BorderStyle.solid),
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
                      child: Icon(
                        _activeTab == 'posted' ? Icons.near_me_outlined : Icons.directions_car_outlined,
                        size: 38,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _activeTab == 'posted' ? 'No rides posted' : 'No rides joined',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _activeTab == 'posted'
                          ? "You haven't requested any rides yet. Click on the Rides tab to post a new request."
                          : "You haven't joined any ride requests yet. Browse the feed and join a ride.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ...activeList.map((ride) => RideCard(ride: ride)),
          ],
        ),
      ),
    );
  }
}
