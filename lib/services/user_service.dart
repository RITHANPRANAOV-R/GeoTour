import 'package:cloud_firestore/cloud_firestore.dart';

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
