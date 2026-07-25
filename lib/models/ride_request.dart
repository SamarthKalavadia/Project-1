import 'user.dart';

class RideRequest {
  final String id;
  final User user;
  final String status; // 'Pending' | 'Accepted' | 'Declined'
  final String timestamp;

  RideRequest({
    required this.id,
    required this.user,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? '',
      user: User.fromJson(Map<String, dynamic>.from(json['user'] ?? {})),
      status: json['status'] ?? 'Pending',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
