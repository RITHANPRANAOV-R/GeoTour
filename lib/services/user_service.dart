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
      "roles": [role],
      "activeRole": role,
      "profileCompleted": false,
      "createdAt": DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserMainDoc(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<void> updateProfileCompleted(String uid, bool value) async {
    await _db.collection("users").doc(uid).set({
      "profileCompleted": value,
    }, SetOptions(merge: true));
  }
}
