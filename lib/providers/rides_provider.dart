import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/ride.dart';
import '../models/ride_request.dart';
import '../models/filters.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

class RidesProvider extends ChangeNotifier {
  List<Ride> _rides = [];
  User? _currentUser;
  bool _authLoading = true;
  Filters _filters = Filters();

  List<Ride> get rides => _rides;
  User? get currentUser => _currentUser;
  bool get authLoading => _authLoading;
  Filters get filters => _filters;

  RidesProvider() {
    _initSession();
    _initRidesListener();
  }

  Future<void> _initSession() async {
    _currentUser = await StorageService.getUserSession();
    _authLoading = false;
    notifyListeners();
  }

  void _initRidesListener() {
    FirebaseService.getRidesStream().listen((updatedRides) {
      if (updatedRides.isNotEmpty) {
        _rides = updatedRides;
        notifyListeners();
      }
    }, onError: (_) {});
  }

  void setFilters(Filters newFilters) {
    _filters = newFilters;
    notifyListeners();
  }

  void clearFilters() {
    _filters = Filters();
    notifyListeners();
  }

  Future<void> login(User user) async {
    _currentUser = user;
    await StorageService.saveUserSession(user);
    await FirebaseService.saveUserToFirestore(user);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    await StorageService.clearUserSession();
    notifyListeners();
  }

  Future<void> updateCurrentUser(User newUser) async {
    _currentUser = newUser;
    await StorageService.saveUserSession(newUser);
    await FirebaseService.saveUserToFirestore(newUser);
    notifyListeners();
  }

  Future<void> addRide({
    required String pickup,
    required String destination,
    required String departureTime,
    required int seatsTotal,
    required String fareEstimate,
    required String notes,
    required String genderPreference,
  }) async {
    if (_currentUser == null) return;

    final newRide = Ride(
      id: 'ride-${DateTime.now().millisecondsSinceEpoch}',
      pickup: pickup,
      destination: destination,
      departureTime: departureTime,
      departureTimestamp: DateTime.now().millisecondsSinceEpoch + 7200000,
      seatsTotal: seatsTotal,
      seatsLeft: seatsTotal,
      fareEstimate: fareEstimate,
      notes: notes,
      status: 'Pending',
      poster: _currentUser!,
      acceptor: null,
      requests: [],
      genderPreference: genderPreference,
    );

    _rides.insert(0, newRide);
    notifyListeners();

    try {
      await FirebaseService.saveRideToFirestore(newRide);
    } catch (_) {}
  }

  Future<void> requestToJoin(String rideId) async {
    if (_currentUser == null) return;

    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;

    final ride = _rides[index];
    final existingReqIndex = ride.requests.indexWhere((req) => req.user.email == _currentUser!.email);
    if (existingReqIndex != -1) return;

    final newRequest = RideRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      user: _currentUser!,
      status: 'Pending',
      timestamp: 'Just now',
    );

    final updatedRequests = List<RideRequest>.from(ride.requests)..add(newRequest);
    final updatedRide = Ride(
      id: ride.id,
      pickup: ride.pickup,
      destination: ride.destination,
      departureTime: ride.departureTime,
      departureTimestamp: ride.departureTimestamp,
      seatsTotal: ride.seatsTotal,
      seatsLeft: ride.seatsLeft,
      fareEstimate: ride.fareEstimate,
      notes: ride.notes,
      status: ride.status,
      poster: ride.poster,
      acceptor: ride.acceptor,
      requests: updatedRequests,
      genderPreference: ride.genderPreference,
    );

    _rides[index] = updatedRide;
    notifyListeners();

    try {
      await FirebaseService.saveRideToFirestore(updatedRide);
    } catch (_) {}
  }

  Future<void> acceptRequest(String rideId, String requestId) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;

    final ride = _rides[index];
    final reqIndex = ride.requests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;

    final acceptedUser = ride.requests[reqIndex].user;
    final updatedRequests = ride.requests.map((r) {
      if (r.id == requestId) {
        return RideRequest(id: r.id, user: r.user, status: 'Accepted', timestamp: r.timestamp);
      } else {
        return RideRequest(id: r.id, user: r.user, status: 'Declined', timestamp: r.timestamp);
      }
    }).toList();

    final updatedRide = Ride(
      id: ride.id,
      pickup: ride.pickup,
      destination: ride.destination,
      departureTime: ride.departureTime,
      departureTimestamp: ride.departureTimestamp,
      seatsTotal: ride.seatsTotal,
      seatsLeft: (ride.seatsLeft - 1).clamp(0, ride.seatsTotal),
      fareEstimate: ride.fareEstimate,
      notes: ride.notes,
      status: 'Accepted',
      poster: ride.poster,
      acceptor: acceptedUser,
      requests: updatedRequests,
      genderPreference: ride.genderPreference,
    );

    _rides[index] = updatedRide;
    notifyListeners();

    try {
      await FirebaseService.saveRideToFirestore(updatedRide);
    } catch (_) {}
  }

  Future<void> declineRequest(String rideId, String requestId) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;

    final ride = _rides[index];
    final updatedRequests = ride.requests.map((r) {
      if (r.id == requestId) {
        return RideRequest(id: r.id, user: r.user, status: 'Declined', timestamp: r.timestamp);
      }
      return r;
    }).toList();

    final updatedRide = Ride(
      id: ride.id,
      pickup: ride.pickup,
      destination: ride.destination,
      departureTime: ride.departureTime,
      departureTimestamp: ride.departureTimestamp,
      seatsTotal: ride.seatsTotal,
      seatsLeft: ride.seatsLeft,
      fareEstimate: ride.fareEstimate,
      notes: ride.notes,
      status: ride.status,
      poster: ride.poster,
      acceptor: ride.acceptor,
      requests: updatedRequests,
      genderPreference: ride.genderPreference,
    );

    _rides[index] = updatedRide;
    notifyListeners();

    try {
      await FirebaseService.saveRideToFirestore(updatedRide);
    } catch (_) {}
  }
}
