import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/ride.dart';
import '../models/ride_request.dart';
import '../models/filters.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

final defaultUser = User(
  name: "Test Rider",
  photo: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
  phone: "9912345678",
  email: "testrider_9912345678@autoshare.com",
  gender: "Male",
);

final List<Ride> initialSeedRides = [
  Ride(
    id: "ride-1",
    pickup: "Central Railway Station",
    destination: "Tech Park Phase 2",
    departureTime: "Today, 05:30 PM",
    departureTimestamp: DateTime.now().millisecondsSinceEpoch + 2 * 60 * 60 * 1000,
    seatsTotal: 3,
    seatsLeft: 2,
    fareEstimate: "₹80 - ₹100",
    notes: "Splitting Uber XL fare evenly. 2 seats open. Non-smoking please.",
    status: "Pending",
    poster: User(
      name: "Aarav Sharma",
      photo: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      phone: "9876543210",
      email: "aarav.sharma@example.com",
      gender: "Male",
    ),
    acceptor: null,
    requests: [
      RideRequest(
        id: "req-mock-1",
        user: defaultUser,
        status: "Pending",
        timestamp: "5:10 PM",
      )
    ],
    genderPreference: "Both",
  ),
  Ride(
    id: "ride-2",
    pickup: "Indiranagar Metro Station",
    destination: "Whitefield ITPB",
    departureTime: "Today, 06:15 PM",
    departureTimestamp: DateTime.now().millisecondsSinceEpoch + 4 * 60 * 60 * 1000,
    seatsTotal: 2,
    seatsLeft: 1,
    fareEstimate: "₹120",
    notes: "Personal Honda City. AC, music system, looking for polite co-passengers.",
    status: "Pending",
    poster: User(
      name: "Priya Patel",
      photo: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
      phone: "9812345678",
      email: "priya.p@company.com",
      gender: "Female",
    ),
    acceptor: null,
    requests: [],
    genderPreference: "Girls only",
  ),
  Ride(
    id: "ride-3",
    pickup: "International Airport T2",
    destination: "Downtown Core",
    departureTime: "Tomorrow, 08:30 AM",
    departureTimestamp: DateTime.now().millisecondsSinceEpoch + 20 * 60 * 60 * 1000,
    seatsTotal: 3,
    seatsLeft: 3,
    fareEstimate: "₹250 - ₹300",
    notes: "Ola Prime Sedan. Have space for luggage. AC will be on.",
    status: "Pending",
    poster: User(
      name: "Rohan Das",
      photo: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
      phone: "9734567890",
      email: "rohan.das@gmail.com",
      gender: "Male",
    ),
    acceptor: null,
    requests: [],
    genderPreference: "Both",
  ),
  Ride(
    id: "ride-4",
    pickup: "University North Campus",
    destination: "Sports Complex",
    departureTime: "Tomorrow, 02:00 PM",
    departureTimestamp: DateTime.now().millisecondsSinceEpoch + 25 * 60 * 60 * 1000,
    seatsTotal: 1,
    seatsLeft: 1,
    fareEstimate: "₹20 - ₹30",
    notes: "Quick auto ride, looking for 1 co-passenger to split.",
    status: "Pending",
    poster: User(
      name: "Sneha Reddy",
      photo: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
      phone: "9645678901",
      email: "sneha.r@university.edu",
      gender: "Female",
    ),
    acceptor: null,
    requests: [],
    genderPreference: "Girls only",
  ),
];

class RidesProvider extends ChangeNotifier {
  List<Ride> _rides = initialSeedRides;
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
    _currentUser ??= defaultUser;
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

  Future<void> cancelRide(String rideId) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;

    final ride = _rides[index];
    final updatedRide = Ride(
      id: ride.id,
      pickup: ride.pickup,
      destination: ride.destination,
      departureTime: ride.departureTime,
      departureTimestamp: ride.departureTimestamp,
      seatsTotal: ride.seatsTotal,
      seatsLeft: ride.seatsTotal,
      fareEstimate: ride.fareEstimate,
      notes: ride.notes,
      status: 'Cancelled',
      poster: ride.poster,
      acceptor: null,
      requests: ride.requests,
      genderPreference: ride.genderPreference,
    );

    _rides[index] = updatedRide;
    notifyListeners();

    try {
      await FirebaseService.saveRideToFirestore(updatedRide);
    } catch (_) {}
  }

  Future<void> completeRide(String rideId) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;

    final ride = _rides[index];
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
      status: 'Completed',
      poster: ride.poster,
      acceptor: ride.acceptor,
      requests: ride.requests,
      genderPreference: ride.genderPreference,
    );

    _rides[index] = updatedRide;
    notifyListeners();

    try {
      await FirebaseService.saveRideToFirestore(updatedRide);
    } catch (_) {}
  }

  Future<void> cancelRequest(String rideId, String email) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;

    final ride = _rides[index];
    final isCurrentlyAccepted = ride.status == 'Accepted' && ride.acceptor?.email == email;
    final newStatus = isCurrentlyAccepted ? 'Pending' : ride.status;
    final newSeatsLeft = isCurrentlyAccepted ? (ride.seatsLeft + 1).clamp(0, ride.seatsTotal) : ride.seatsLeft;
    final newAcceptor = isCurrentlyAccepted ? null : ride.acceptor;

    final updatedRequests = ride.requests
        .where((r) => r.user.email != email)
        .map((r) {
          if (isCurrentlyAccepted && r.status == 'Declined') {
            return RideRequest(id: r.id, user: r.user, status: 'Pending', timestamp: r.timestamp);
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
      seatsLeft: newSeatsLeft,
      fareEstimate: ride.fareEstimate,
      notes: ride.notes,
      status: newStatus,
      poster: ride.poster,
      acceptor: newAcceptor,
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

