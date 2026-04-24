import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserMainDoc({
    required String uid,
    required String email,
    required String role,
  }) async {
    await _db.collection("users").doc(uid).set({
      "email": email,
      "roles": FieldValue.arrayUnion([role]),
      "activeRole": role,
      "createdAt": DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Initialize role completion if it doesn't exist
    await _db.collection("users").doc(uid).set({
      "roleCompletion": {role: false},
    }, SetOptions(merge: true));

    if (role == "tourist") {
      final touristId = await generateTouristId(uid);
      await _db.collection("users").doc(uid).set({
        "touristId": touristId,
      }, SetOptions(merge: true));
    }
  }

  Future<String> generateTouristId(String uid) async {
    // Check if user already has an ID
    final doc = await _db.collection("users").doc(uid).get();
    if (doc.exists && doc.data()?.containsKey("touristId") == true) {
      return doc.data()!["touristId"];
    }

    final year = DateTime.now().year;
    final random = Random().nextInt(8999) + 1000; // 1000 to 9999
    final touristId = "GT-$year-$random";
    return touristId;
  }

  Future<Map<String, dynamic>?> getUserMainDoc(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<void> updateProfileCompleted(
    String uid,
    bool value,
    String role,
  ) async {
    await _db.collection("users").doc(uid).set({
      "roleCompletion": {role: value},
      // Keep global flag for backward compatibility if needed, but per-role is primary
      "profileCompleted": value,
    }, SetOptions(merge: true));
  }

  Future<void> switchRole(String uid, String newRole) async {
    await _db.collection("users").doc(uid).update({"activeRole": newRole});
  }
}
