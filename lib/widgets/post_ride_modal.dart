import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class PostRideModal extends StatefulWidget {
  const PostRideModal({super.key});

  @override
  State<PostRideModal> createState() => _PostRideModalState();
}

class _PostRideModalState extends State<PostRideModal> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _timeController = TextEditingController(text: 'Today, 06:00 PM');
  final _fareController = TextEditingController(text: '₹50 - ₹80');
  final _notesController = TextEditingController();
  int _seatsTotal = 3;
  String _genderPreference = 'Both';
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
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _timeController.dispose();
    _fareController.dispose();
    _notesController.dispose();
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
                  'Offer a Ride',
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
                labelText: 'Pickup Location *',
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
                labelText: 'Destination Location *',
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
            const SizedBox(height: 12),

            // Departure Time & Fare Share Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      labelText: 'Departure Time',
                      labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
                      prefixIcon: Icon(Icons.access_time, color: primary, size: 20),
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fareController,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      labelText: 'Fare Share',
                      labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
                      prefixIcon: Icon(Icons.payments, color: primary, size: 20),
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
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Seats Available Selector (Scrollable to prevent yellow/black lines!)
            Text(
              'Seats Available',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [1, 2, 3, 4, 5, 6].map((s) {
                  final isSel = _seatsTotal == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '$s Seats',
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
                      onSelected: (sel) {
                        if (sel) setState(() => _seatsTotal = s);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Gender Preference Selector (Scrollable to prevent yellow/black lines!)
            Text(
              'Gender Preference',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Both', 'Boys only', 'Girls only'].map((g) {
                  final isSel = _genderPreference == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        g,
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
                      onSelected: (sel) {
                        if (sel) setState(() => _genderPreference = g);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Ride Notes Input
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                labelText: 'Ride Notes (e.g. AC car, luggage space)',
                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                prefixIcon: Icon(Icons.notes, color: primary),
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
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_pickupController.text.trim().isEmpty || _destinationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in pickup and destination locations')),
                    );
                    return;
                  }

                  context.read<RidesProvider>().addRide(
                        pickup: _pickupController.text.trim(),
                        destination: _destinationController.text.trim(),
                        departureTime: _timeController.text.trim(),
                        seatsTotal: _seatsTotal,
                        fareEstimate: _fareController.text.trim(),
                        notes: _notesController.text.trim(),
                        genderPreference: _genderPreference,
                      );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Post Ride Offer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
