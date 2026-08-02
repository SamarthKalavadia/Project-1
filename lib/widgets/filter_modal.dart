import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../models/filters.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  int? _selectedSeats;
  late String _timeSlot;
  late String _genderPreference;
  bool _fetchingLocation = false;

  Future<void> _useLiveLocation(TextEditingController controller) async {
    setState(() => _fetchingLocation = true);
    final locationData = await LocationService.getCurrentLocationWithAddress();
    if (!mounted) return;
    setState(() => _fetchingLocation = false);

    if (locationData != null && locationData['address'] != null) {
      controller.text = locationData['address'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Live GPS Location set: ${locationData['address']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to fetch live GPS location. Please check location permissions.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final filters = context.read<RidesProvider>().filters;
    _pickupController = TextEditingController(text: filters.pickup);
    _destinationController = TextEditingController(text: filters.destination);
    _selectedSeats = filters.seats;
    _timeSlot = filters.timeSlot;
    _genderPreference = filters.genderPreference;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Rides',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pickup Location Input
            TextField(
              controller: _pickupController,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                labelText: 'Pickup Location',
                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                prefixIcon: Icon(Icons.my_location, color: primary),
                suffixIcon: IconButton(
                  icon: _fetchingLocation
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.gps_fixed, color: primary),
                  tooltip: 'Use Live GPS Location',
                  onPressed: () => _useLiveLocation(_pickupController),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Destination Location Input
            TextField(
              controller: _destinationController,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                labelText: 'Destination',
                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                prefixIcon: Icon(Icons.location_on, color: primary),
                suffixIcon: IconButton(
                  icon: _fetchingLocation
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.gps_fixed, color: primary),
                  tooltip: 'Use Live GPS Location',
                  onPressed: () => _useLiveLocation(_destinationController),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Seats Available Selection (Scrollable to prevent yellow/black lines!)
            Text(
              'Minimum Seats Available',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [null, 1, 2, 3, 4].map((s) {
                  final isSel = _selectedSeats == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        s == null ? 'Any' : '$s+ Seats',
                        style: TextStyle(
                          color: isSel ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: primary,
                      backgroundColor: inputBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        setState(() {
                          _selectedSeats = selected ? s : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Gender Preference Filter (Scrollable to prevent yellow/black lines!)
            Text(
              'Gender Preference',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  {'id': 'all', 'label': 'All Rides'},
                  {'id': 'Boys only', 'label': 'Boys only'},
                  {'id': 'Girls only', 'label': 'Girls only'},
                ].map((g) {
                  final isSel = _genderPreference == g['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        g['label']!,
                        style: TextStyle(
                          color: isSel ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: primary,
                      backgroundColor: inputBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        setState(() {
                          _genderPreference = selected ? g['id']! : 'all';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.read<RidesProvider>().clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset Filters',
                      style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.read<RidesProvider>().setFilters(
                            Filters(
                              pickup: _pickupController.text.trim(),
                              destination: _destinationController.text.trim(),
                              seats: _selectedSeats,
                              timeSlot: _timeSlot,
                              genderPreference: _genderPreference,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
