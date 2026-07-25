import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget fallbackAvatar() {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0D9488),
              const Color(0xFF0F766E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.9,
            ),
          ),
        ),
      );
    }

    if (photoUrl.isEmpty) {
      return fallbackAvatar();
    }

    // Handle Base64 encoded images
    if (photoUrl.startsWith('data:image') || photoUrl.length > 300) {
      try {
        final cleanBase64 = photoUrl.contains(',')
            ? photoUrl.split(',').last
            : photoUrl;
        final bytes = base64Decode(cleanBase64.trim());
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            bytes,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallbackAvatar(),
          ),
        );
      } catch (_) {
        return fallbackAvatar();
      }
    }

    // Handle Local File paths
    if (photoUrl.startsWith('/') || photoUrl.startsWith('file://')) {
      try {
        final cleanPath = photoUrl.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.file(
              file,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallbackAvatar(),
            ),
          );
        }
      } catch (_) {
        return fallbackAvatar();
      }
    }

    // Handle Network Image URLs
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          photoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackAvatar(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    return fallbackAvatar();
  }
}
