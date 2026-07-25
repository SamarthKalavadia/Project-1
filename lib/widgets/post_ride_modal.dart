import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
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
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Offer a Ride',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                labelText: 'Pickup Location *',
                prefixIcon: Icon(Icons.my_location, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Destination Location *',
                prefixIcon: Icon(Icons.location_on, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Departure Time',
                      prefixIcon: Icon(Icons.access_time, color: primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fareController,
                    decoration: InputDecoration(
                      labelText: 'Fare Share',
                      prefixIcon: Icon(Icons.payments, color: primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Seats Available', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [1, 2, 3, 4, 5, 6].map((s) {
                final isSel = _seatsTotal == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$s Seats'),
                    selected: isSel,
                    selectedColor: primary,
                    onSelected: (sel) {
                      if (sel) setState(() => _seatsTotal = s);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Gender Preference', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: ['Both', 'Boys only', 'Girls only'].map((g) {
                final isSel = _genderPreference == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: isSel,
                    selectedColor: primary,
                    onSelected: (sel) {
                      if (sel) setState(() => _genderPreference = g);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Ride Notes (e.g. AC car, luggage space)',
                prefixIcon: Icon(Icons.notes, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                child: const Text('Post Ride Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
