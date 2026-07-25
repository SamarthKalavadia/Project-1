import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import '../models/ride.dart';

class FirebaseService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static fb_auth.FirebaseAuth get _auth => fb_auth.FirebaseAuth.instance;

  static const String ridesCollection = 'rides';
  static const String usersCollection = 'users';

  /// Send Real-time SMS OTP via Firebase Auth
  static Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMsg) onError,
  }) async {
    final formattedPhone = phoneNumber.startsWith('+')
        ? phoneNumber
        : '+91${phoneNumber.replaceAll(RegExp(r'\D'), '')}';

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        if (e.code == 'billing-not-enabled') {
          onError('Firebase Billing Required: Upgrade to Firebase Blaze plan or add test phone number in Firebase Console.');
        } else if (e.code == 'operation-not-allowed') {
          onError('Firebase SMS disabled for this region. Enable Phone Auth & SMS Region Policy (+91 India) in Firebase Console.');
        } else {
          onError(e.message ?? 'Phone verification failed');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Verify OTP Code
  static Future<fb_auth.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = fb_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
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

  /// Save or update user in Firestore
  static Future<void> saveUserToFirestore(User user) async {
    await _db
        .collection(usersCollection)
        .doc(user.phone)
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
