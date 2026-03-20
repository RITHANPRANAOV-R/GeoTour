import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Alerts ---
  Stream<QuerySnapshot> getAlertsStream() {
    return _firestore
        .collection('alerts')
        .where('status', isNotEqualTo: 'completed')
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
    String status = isAvailable ? 'available' : 'offline';
    await _firestore.collection('police').doc(uid).update({
      'isAvailable': isAvailable,
      'status': status,
    });
    // Also update in officers collection for assignments
    final officerQuery = await _firestore.collection('officers').where('uid', isEqualTo: uid).get();
    for (var doc in officerQuery.docs) {
      await doc.reference.update({
        'isAvailable': isAvailable,
        'status': status,
      });
    }
  }

  // --- Mission Management ---

  Future<bool> acceptAlert({
    required String alertId,
    required String officerId,
    required String officerName,
  }) async {
    return await _firestore.runTransaction((transaction) async {
      DocumentReference alertRef = _firestore.collection('alerts').doc(alertId);
      DocumentSnapshot alertSnapshot = await transaction.get(alertRef);

      if (!alertSnapshot.exists) return false;

      final alertData = alertSnapshot.data() as Map<String, dynamic>;
      if (alertData.containsKey('acceptedBy') && alertData['acceptedBy'] != null) {
        return false; // Already accepted by someone else
      }

      // Update Alert
      transaction.update(alertRef, {
        'acceptedBy': officerId,
        'acceptedByName': officerName,
        'status': 'assigned',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update Officer Status
      DocumentReference officerRef = _firestore.collection('police').doc(officerId);
      transaction.update(officerRef, {
        'status': 'on_mission',
        'isAvailable': false,
      });

      return true;
    });
  }

  Future<void> completeMission({
    required String alertId,
    required String officerId,
    required Map<String, dynamic> alertData,
  }) async {
    WriteBatch batch = _firestore.batch();

    // Move to Incidents
    DocumentReference incidentRef = _firestore.collection('incidents').doc();
    batch.set(incidentRef, {
      'victimName': alertData['name'] ?? 'Unknown',
      'summary': "Police response completed for threat: ${alertData['threat'] ?? 'N/A'}",
      'riskLevel': alertData['riskLevel'] ?? 'High',
      'officerId': officerId,
      'officerName': alertData['acceptedByName'] ?? 'Officer',
      'alertId': alertId,
      'timestamp': FieldValue.serverTimestamp(),
      'alertDetails': alertData,
    });

    // Mark Alert as completed
    DocumentReference alertRef = _firestore.collection('alerts').doc(alertId);
    batch.update(alertRef, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Reset Officer Status
    DocumentReference officerRef = _firestore.collection('police').doc(officerId);
    batch.update(officerRef, {
      'status': 'available',
      'isAvailable': true,
    });

    await batch.commit();
  }

}
