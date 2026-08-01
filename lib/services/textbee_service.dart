import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class TextBeeService {
  static const String apiKey = '7d4750a0-9b85-4e73-802d-d3a9de609ecd';
  static const String baseUrl = 'https://api.textbee.dev/api/v1/gateway';

  /// Connected TextBee Android Device ID
  static String configuredDeviceId = '6a6d961925b54ad14b55a5f3';

  /// Format phone number into standard E.164 (+91XXXXXXXXXX) format
  static String formatPhoneNumber(String phone)
   {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('+')) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    return '+$digits';
  }

  /// Get list of connected Android gateway devices from TextBee API
  static Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$baseUrl/devices'));
      request.headers.set('x-api-key', apiKey);
      final response = await request.close();
      final bodyStr = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final json = jsonDecode(bodyStr);
        if (json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
      debugPrint('TextBee getDevices status ${response.statusCode}: $bodyStr');
      return [];
    } catch (e) {
      debugPrint('TextBee getDevices error: $e');
      return [];
    }
  }

  /// Send real-time SMS to recipient phone number using TextBee Gateway API
  static Future<Map<String, dynamic>> sendSms({
    required String phone,
    required String message,
    String? deviceId,
  }) async {
    try {
      final recipient = formatPhoneNumber(phone);

      // Determine device ID: explicit parameter > configuredDeviceId > dynamically fetched device from account
      String targetDeviceId = deviceId ?? configuredDeviceId;
      if (targetDeviceId.isEmpty) {
        final devices = await getDevices();
        if (devices.isNotEmpty) {
          final firstDevice = devices.first;
          targetDeviceId = (firstDevice['_id'] ?? firstDevice['id'] ?? firstDevice['deviceId'] ?? '').toString();
        }
      }

      if (targetDeviceId.isEmpty) {
        const errorMsg = 'TextBee Device ID missing: No active Android Gateway device linked to API Key on textbee.dev dashboard.';
        debugPrint('TextBee sendSms error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg,
          'needDeviceRegistration': true,
        };
      }

      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/devices/$targetDeviceId/send-sms');

      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json');
      request.headers.set('x-api-key', apiKey);

      final payload = {
        'recipients': [recipient],
        'message': message,
      };

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final bodyStr = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint('TextBee sendSms status (${response.statusCode}): $bodyStr');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'response': bodyStr,
        };
      } else {
        return {
          'success': false,
          'error': 'TextBee Server Error (${response.statusCode}): $bodyStr',
        };
      }
    } catch (e) {
      debugPrint('TextBee sendSms Exception: $e');
      return {
        'success': false,
        'error': 'Network/Connection Exception: $e',
      };
    }
  }

  /// Generate a random 6-digit OTP and send via TextBee SMS Gateway
  static Future<Map<String, dynamic>> sendOtpSms(String phone) async {
    final otp = (100000 + Random().nextInt(900000)).toString();
    final message = 'AutoShare Code: $otp is your login verification OTP. Do not share with anyone.';
    final result = await sendSms(phone: phone, message: message);
    return {
      'success': result['success'] == true,
      'otp': otp,
      'phone': phone,
      'error': result['error'],
      'needDeviceRegistration': result['needDeviceRegistration'] == true,
    };
  }

  /// Send Ride Request Notification SMS to Poster
  static Future<Map<String, dynamic>> sendRideRequestNotification({
    required String posterPhone,
    required String requesterName,
    required String pickup,
    required String destination,
  }) async {
    final message = 'AutoShare Alert: $requesterName requested to join your ride from $pickup to $destination. Open AutoShare app to accept or decline.';
    return await sendSms(phone: posterPhone, message: message);
  }

  /// Send Ride Acceptance Notification SMS to Passenger
  static Future<Map<String, dynamic>> sendRideAcceptedNotification({
    required String passengerPhone,
    required String posterName,
    required String posterPhone,
    required String pickup,
    required String destination,
  }) async {
    final message = 'AutoShare Alert: Your ride request ($pickup to $destination) was ACCEPTED by $posterName ($posterPhone)! Enjoy your ride.';
    return await sendSms(phone: passengerPhone, message: message);
  }
}
