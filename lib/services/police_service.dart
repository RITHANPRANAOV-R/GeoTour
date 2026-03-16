import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Alerts ---
  Stream<QuerySnapshot> getAlertsStream() {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- Officers ---
  Stream<QuerySnapshot> getOfficersStream() {
    return _firestore.collection('police').snapshots();
  }

  Future<void> updateOfficerStatus(String id, String status) async {
    await _firestore.collection('police').doc(id).update({
      'status': status,
    });
  }

  // --- Incidents ---
  Stream<QuerySnapshot> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> createIncident({
    required String victimName,
    required String summary,
    required String riskLevel,
  }) async {
    await _firestore.collection('incidents').add({
      'victimName': victimName,
      'summary': summary,
      'riskLevel': riskLevel,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Profile ---
  Future<DocumentSnapshot> getOfficerProfile(String uid) async {
    return await _firestore.collection('police').doc(uid).get();
  }

  Future<void> updateAvailability(String uid, bool isAvailable) async {
    await _firestore.collection('police').doc(uid).update({
      'isAvailable': isAvailable,
    });
    // Also update in officers collection for assignments
    final officerQuery = await _firestore.collection('officers').where('uid', isEqualTo: uid).get();
    for (var doc in officerQuery.docs) {
      await doc.reference.update({'isAvailable': isAvailable});
    }
  }
}
