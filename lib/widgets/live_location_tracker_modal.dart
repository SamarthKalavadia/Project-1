import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

class LiveLocationTrackerModal extends StatefulWidget {
  final Ride ride;

  const LiveLocationTrackerModal({super.key, required this.ride});

  @override
  State<LiveLocationTrackerModal> createState() => _LiveLocationTrackerModalState();
}

class _LiveLocationTrackerModalState extends State<LiveLocationTrackerModal> {
  Position? _currentPosition;
  String _currentAddress = 'Fetching real-time GPS location...';
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSub;

  @override
  void initState() {
    super.initState();
    _initLiveTracking();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _initLiveTracking() async {
    setState(() => _isLoading = true);

    // Initial location fetch
    final locationData = await LocationService.getCurrentLocationWithAddress();
    if (mounted && locationData != null) {
      setState(() {
        _currentPosition = locationData['position'] as Position?;
        _currentAddress = locationData['address'] as String;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _currentAddress = 'Location permission not granted or GPS disabled.';
        _isLoading = false;
      });
    }

    // Subscribe to live continuous GPS updates
    _positionStreamSub = LocationService.getLiveLocationStream().listen((Position position) async {
      final address = await LocationService.getAddressFromCoordinates(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (address != null && address.isNotEmpty) {
            _currentAddress = address;
          }
        });
      }
    });
  }

  Future<void> _manualRefresh() async {
    setState(() => _isLoading = true);
    final locationData = await LocationService.getCurrentLocationWithAddress();
    if (mounted && locationData != null) {
      setState(() {
        _currentPosition = locationData['position'] as Position?;
        _currentAddress = locationData['address'] as String;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live GPS position refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title with Live Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Real-Time Live Location',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sensors, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'LIVE GPS',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Host & Ride Info Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  UserAvatar(photoUrl: ride.poster.photo, name: ride.poster.name, radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Host: ${ride.poster.name}',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride.pickup} → ${ride.destination}',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Location Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Current Live Address:',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Reading GPS satellite coordinates...'),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      _currentAddress,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 12),

                    if (_currentPosition != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Latitude',
                              value: _currentPosition!.latitude.toStringAsFixed(5),
                              icon: Icons.explore,
                              primaryColor: primary,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              cardBg: cardBg,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Longitude',
                              value: _currentPosition!.longitude.toStringAsFixed(5),
                              icon: Icons.map,
                              primaryColor: primary,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              cardBg: cardBg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Speed',
                              value: '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                              icon: Icons.speed,
                              primaryColor: primary,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              cardBg: cardBg,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'GPS Accuracy',
                              value: '±${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                              icon: Icons.gps_fixed,
                              primaryColor: primary,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              cardBg: cardBg,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _manualRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textSecondary, fontSize: 10)),
                Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
