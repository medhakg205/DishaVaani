import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interest_profile.dart';
import 'device_identity.dart';

/// Firestore shape:
///   Collection: interest_profiles
///   Document ID: <deviceId>   (from DeviceIdentity.getId())
///   Fields:
///     categories   : Map<String, double>
///     quizVersion  : int
///     createdAt    : Timestamp
///     updatedAt    : Timestamp
class ProfileStore {
  static const String collectionName = 'interest_profiles';
  static const int currentQuizVersion = 1;

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Call right after interest_quiz.dart finishes scoring.
  Future<void> saveInitialProfile(InterestProfile profile) async {
    final deviceId = await DeviceIdentity.getId();
    await _col.doc(deviceId).set({
      'categories': profile.toJson(),
      'quizVersion': currentQuizVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Call on app start. Returns an empty profile if this device has
  /// never completed the quiz.
  Future<InterestProfile> loadProfile() async {
    final deviceId = await DeviceIdentity.getId();
    final snap = await _col.doc(deviceId).get();
    if (!snap.exists) return InterestProfile.empty();
    final data = snap.data();
    final categories = data?['categories'] as Map<String, dynamic>? ?? {};
    return InterestProfile.fromJson(categories);
  }
}