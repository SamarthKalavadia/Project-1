import 'user.dart';
import 'ride_request.dart';

class Ride {
  final String id;
  final String pickup;
  final String destination;
  final String departureTime;
  final int departureTimestamp;
  final int seatsTotal;
  final int seatsLeft;
  final String fareEstimate;
  final String notes;
  final String status; // 'Pending' | 'Accepted' | 'Completed' | 'Cancelled'
  final User poster;
  final User? acceptor;
  final List<RideRequest> requests;
  final String genderPreference; // 'Boys only' | 'Girls only' | 'Both'

  Ride({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.departureTimestamp,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.fareEstimate,
    required this.notes,
    required this.status,
    required this.poster,
    this.acceptor,
    required this.requests,
    required this.genderPreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickup': pickup,
      'destination': destination,
      'departureTime': departureTime,
      'departureTimestamp': departureTimestamp,
      'seatsTotal': seatsTotal,
      'seatsLeft': seatsLeft,
      'fareEstimate': fareEstimate,
      'notes': notes,
      'status': status,
      'poster': poster.toJson(),
      'acceptor': acceptor?.toJson(),
      'requests': requests.map((r) => r.toJson()).toList(),
      'genderPreference': genderPreference,
    };
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? '',
      pickup: json['pickup'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: json['departureTime'] ?? '',
      departureTimestamp: json['departureTimestamp'] ?? 0,
      seatsTotal: json['seatsTotal'] ?? 1,
      seatsLeft: json['seatsLeft'] ?? 1,
      fareEstimate: json['fareEstimate'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Pending',
      poster: User.fromJson(Map<String, dynamic>.from(json['poster'] ?? {})),
      acceptor: json['acceptor'] != null
          ? User.fromJson(Map<String, dynamic>.from(json['acceptor']))
          : null,
      requests: (json['requests'] as List? ?? [])
          .map((r) => RideRequest.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      genderPreference: json['genderPreference'] ?? 'Both',
    );
  }
}
