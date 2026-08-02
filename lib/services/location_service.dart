import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final Geocoding _geocoding = Geocoding();

  /// Check and request location permissions
  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled on the device.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  /// Get current live GPS position of the user
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Convert (latitude, longitude) into readable address string
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final String name = (place.name != null && place.name != place.street) ? place.name! : '';
        final String street = place.street ?? place.subLocality ?? '';
        final String locality = place.locality ?? place.subAdministrativeArea ?? '';
        final String administrativeArea = place.administrativeArea ?? '';

        final List<String> parts = [name, street, locality, administrativeArea]
            .where((String p) => p.isNotEmpty)
            .toSet()
            .toList();

        return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Error reverse geocoding coordinates: $e');
    }
    return null;
  }

  /// Fetch current position and return human-readable location address string
  static Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final address = await getAddressFromCoordinates(position.latitude, position.longitude);

    return {
      'position': position,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address ?? 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
    };
  }

  /// Subscribe to live GPS position stream for real-time location tracking
  static Stream<Position> getLiveLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Notify every 10 meters change
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance in km between two GPS coordinates
  static double calculateDistanceInKm(double startLat, double startLng, double endLat, double endLng) {
    final distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    return distanceInMeters / 1000.0;
  }
}
