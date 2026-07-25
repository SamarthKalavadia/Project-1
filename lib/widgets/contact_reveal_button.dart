import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContactRevealButton extends StatefulWidget {
  final String phoneNumber;

  const ContactRevealButton({super.key, required this.phoneNumber});

  @override
  State<ContactRevealButton> createState() => _ContactRevealButtonState();
}

class _ContactRevealButtonState extends State<ContactRevealButton> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (_revealed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone, size: 16, color: primary),
            const SizedBox(width: 6),
            Text(
              '+91 ${widget.phoneNumber}',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () {
        setState(() {
          _revealed = true;
        });
      },
      icon: const Icon(Icons.call, size: 16),
      label: const Text(
        'Call Driver',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
