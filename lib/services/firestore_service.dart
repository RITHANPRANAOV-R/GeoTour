import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> checkUserExists(String collection, String uid) async {
    final doc = await _db.collection(collection).doc(uid).get();
    return doc.exists;
  }

  Future<void> createUserDoc({
    required String collection,
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(collection).doc(uid).set(data);
  }

  Future<Map<String, dynamic>?> getUserData(String collection, String uid) async {
    final doc = await _db.collection(collection).doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
