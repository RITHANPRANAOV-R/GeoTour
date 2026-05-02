import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/officer_model.dart';

class PoliceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Alerts ---
  Stream<QuerySnapshot> getAlertsStream() {
    return _firestore
        .collection('alerts')
        .where('status', isNotEqualTo: 'completed')
        .snapshots();
  }

  Stream<DocumentSnapshot> getAlertStream(String alertId) {
    return _firestore.collection('alerts').doc(alertId).snapshots();
  }

  Stream<QuerySnapshot> getUserAlertsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- Officers ---
  Stream<QuerySnapshot> getOfficersStream() {
    return _firestore.collection('police').snapshots();
  }

  Stream<List<OfficerModel>> getAvailableOfficersStream() {
    return _firestore
        .collection('police')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OfficerModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> updateOfficerStatus(String id, String status) async {
    await _firestore.collection('police').doc(id).update({'status': status});
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

  Stream<DocumentSnapshot> getOfficerProfileStream(String uid) {
    return _firestore.collection('police').doc(uid).snapshots();
  }

  Future<void> updateAvailability(String uid, bool isAvailable) async {
    String status = isAvailable ? 'available' : 'offline';
    await _firestore.collection('police').doc(uid).set({
      'isAvailable': isAvailable,
      'status': status,
    }, SetOptions(merge: true));
    // Also update in officers collection for assignments
    final officerQuery = await _firestore
        .collection('officers')
        .where('uid', isEqualTo: uid)
        .get();
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
      final String? currentAcceptedBy = alertData['acceptedBy'];

      if (currentAcceptedBy != null && currentAcceptedBy.isNotEmpty) {
        return false; // Already accepted by someone else
      }

      // Update Alert
      final updateData = {
        'acceptedBy': officerId,
        'acceptedByName': officerName,
        'status': 'assigned',
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      transaction.update(alertRef, updateData);

      // Update victim's sub-collection if userId or victimId exists
      final String? victimId = alertData['userId'] ?? alertData['victimId'];
      if (victimId != null) {
        DocumentReference userAlertRef = _firestore
            .collection('users')
            .doc(victimId)
            .collection('alerts')
            .doc(alertId);
        transaction.update(userAlertRef, updateData);
      }

      // Update Officer Status
      DocumentReference officerRef = _firestore
          .collection('police')
          .doc(officerId);
      transaction.update(officerRef, {
        'status': 'on_mission',
        'isAvailable': false,
      });

      return true;
    });
  }

  Future<bool> assignAlert({
    required String alertId,
    required String officerId,
    required String officerName,
  }) async {
    return await acceptAlert(
      alertId: alertId,
      officerId: officerId,
      officerName: officerName,
    );
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
      'summary':
          "Police response completed for threat: ${alertData['threat'] ?? 'N/A'}",
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
    DocumentReference officerRef = _firestore
        .collection('police')
        .doc(officerId);
    batch.update(officerRef, {'status': 'available', 'isAvailable': true});

    await batch.commit();
  }

  Future<String?> triggerAlert({
    required String name,
    required String threat,
    required String riskLevel,
    required double lat,
    required double lng,
    String? userId,
    String? phone,
    String? contacts,
    String? touristId,
  }) async {
    final alertData = {
      'name': name,
      'threat': threat,
      'riskLevel': riskLevel,
      'location': GeoPoint(lat, lng),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'automated',
      'userId': userId,
      'phone': phone,
      'contacts': contacts,
      'touristId': touristId,
    };

    try {
      // 1. Global collection for Police
      final globalDoc = await _firestore.collection('alerts').add(alertData);

      // 2. User-specific history
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('alerts')
            .doc(globalDoc.id) // Use same ID for consistency
            .set(alertData);
      }

      return globalDoc.id;
    } catch (e) {
      debugPrint("Error triggering alert: $e");
      return null;
    }
  }

  Future<void> updateAlertLocation(
    String alertId, {
    required double lat,
    required double lng,
    String? userId,
  }) async {
    final location = GeoPoint(lat, lng);

    // 1. Update Global Alert
    await _firestore.collection('alerts').doc(alertId).update({
      'location': location,
    });

    // 2. Update User-specific Alert (Optional history)
    if (userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('alerts')
            .doc(alertId)
            .update({'location': location});
      } catch (e) {
        // Might not exist if history is suppressed
      }
    }
  }

  Future<void> updateOfficerLocation(String uid, double lat, double lng) async {
    await _firestore.collection('police').doc(uid).set({
      'location': GeoPoint(lat, lng),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> triggerPoliceSOS({
    required String victimId,
    required String victimName,
    required double lat,
    required double lng,
    required String threat,
    required String riskLevel,
    String? medicalInfo,
    String? officerId,
    String? phone,
    String? contacts,
    String? touristId,
  }) async {
    final alertData = {
      'victimId': victimId,
      'victimName': victimName,
      'threat': threat,
      'riskLevel': riskLevel,
      'medicalInfo': medicalInfo,
      'phone': phone,
      'contacts': contacts,
      'location': GeoPoint(lat, lng),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'targeted',
      'targetedOfficerId': officerId,
      'touristId': touristId,
    };

    // 1. Global collection
    final globalDoc = await _firestore.collection('alerts').add(alertData);

    // 2. User history
    await _firestore
        .collection('users')
        .doc(victimId)
        .collection('alerts')
        .doc(globalDoc.id)
        .set(alertData);

    // 3. Officer specific targeted alert?
    // Usually officer listens to global 'alerts' and filters by targetedOfficerId or priority.
  }
}
