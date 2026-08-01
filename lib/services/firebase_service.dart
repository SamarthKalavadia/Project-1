import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import '../models/ride.dart';

class FirebaseService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static fb_auth.FirebaseAuth get _auth => fb_auth.FirebaseAuth.instance;

  static const String ridesCollection = 'rides';
  static const String usersCollection = 'users';

  /// Get current Firebase Auth user
  static fb_auth.User? get currentFbUser => _auth.currentUser;

  /// Send Email Verification via Firebase Auth
  static Future<bool> sendFirebaseEmailVerification({
    required String email,
    required String password,
  }) async {
    fb_auth.User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email?.toLowerCase() != email.toLowerCase()) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        currentUser = credential.user;
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          try {
            final credential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            currentUser = credential.user;
          } catch (_) {
            rethrow;
          }
        } else if (e.code == 'operation-not-allowed') {
          throw Exception('Email/Password provider is disabled in Firebase Console. Enable "Email/Password" under Auth -> Sign-in method tab.');
        } else {
          rethrow;
        }
      } catch (e) {
        rethrow;
      }
    }

    if (currentUser != null) {
      try {
        await currentUser.reload();
        if (!currentUser.emailVerified) {
          await currentUser.sendEmailVerification();
          return false;
        }
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Resend verification email
  static Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Send Password Reset Email Link via Firebase Auth
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Check if email is verified
  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Fetch user from Firestore by phone number
  static Future<User?> getUserFromFirestore(String phone) async {
    try {
      final docSnap = await _db.collection(usersCollection).doc(phone).get();
      if (docSnap.exists && docSnap.data() != null) {
        return User.fromJson(docSnap.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch user from Firestore by email
  static Future<User?> getUserByEmailFromFirestore(String email) async {
    try {
      final query = await _db
          .collection(usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return User.fromJson(query.docs.first.data());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save or update user in Firestore
  static Future<void> saveUserToFirestore(User user) async {
    await _db
        .collection(usersCollection)
        .doc(user.phone.isNotEmpty ? user.phone : user.email)
        .set(user.toJson(), SetOptions(merge: true));
  }

  /// Subscribe to Rides stream from Firestore
  static Stream<List<Ride>> getRidesStream() {
    return _db.collection(ridesCollection).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Ride.fromJson(data);
      }).toList();
      list.sort((a, b) => b.departureTimestamp.compareTo(a.departureTimestamp));
      return list;
    });
  }

  /// Save a ride to Firestore
  static Future<void> saveRideToFirestore(Ride ride) async {
    await _db
        .collection(ridesCollection)
        .doc(ride.id)
        .set(ride.toJson(), SetOptions(merge: true));
  }
}
