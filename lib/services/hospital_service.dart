import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hospital_model.dart';

class HospitalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<HospitalModel>> getNearestHospitalsStream() {
    return _firestore.collection('hospitals').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HospitalModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<HospitalModel>> getActiveHospitalsStream() {
    return _firestore
        .collection('hospitals')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HospitalModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> updateHospitalStatus(String hospitalId, bool isAvailable) async {
    await _firestore.collection('hospitals').doc(hospitalId).update({
      'isAvailable': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getHospitalAlertsStream(String hospitalId) {
    return _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('alerts')
        .snapshots();
  }

  Stream<QuerySnapshot> getHospitalCasesStream(String hospitalId) {
    return _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('alerts')
        .where('status', whereIn: ['ongoing', 'completed', 'transferred'])
        .snapshots();
  }

  Future<void> acceptCase(String hospitalId, String alertId) async {
    // Fetch global alert to ensure we have the full data for the subcollection
    final globalAlert = await _firestore.collection('hospital_alerts').doc(alertId).get();
    
    if (!globalAlert.exists) throw Exception("Alert not found");
    
    final alertData = globalAlert.data()!;
    alertData['status'] = 'ongoing';
    alertData['acceptedAt'] = FieldValue.serverTimestamp();
    alertData['targetHospitalId'] = hospitalId;

    final batch = _firestore.batch();
    
    // 1. Update hospital sub-collection with full data so Cases tab displays correctly
    batch.set(
      _firestore.collection('hospitals').doc(hospitalId).collection('alerts').doc(alertId),
      alertData,
      SetOptions(merge: true)
    );

    // 2. Update global hospital_alerts collection to claim the case
    batch.update(
      _firestore.collection('hospital_alerts').doc(alertId),
      {
        'status': 'ongoing',
        'acceptedAt': FieldValue.serverTimestamp(),
        'targetHospitalId': hospitalId,
      }
    );

    await batch.commit();
  }

  Future<void> completeCase(
    String hospitalId,
    String alertId,
    String description,
  ) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('hospitals').doc(hospitalId).collection('alerts').doc(alertId),
      {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'caseDescription': description,
      }
    );

    batch.update(
      _firestore.collection('hospital_alerts').doc(alertId),
      {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'caseDescription': description,
      }
    );

    await batch.commit();
  }

  Future<void> transferCase({
    required String fromHospitalId,
    required String toHospitalId,
    required String alertId,
    required Map<String, dynamic> alertData,
  }) async {
    final batch = _firestore.batch();

    // 1. Mark as transferred in old hospital
    final oldRef = _firestore
        .collection('hospitals')
        .doc(fromHospitalId)
        .collection('alerts')
        .doc(alertId);
    batch.update(oldRef, {
      'status': 'transferred',
      'transferredTo': toHospitalId,
      'transferredAt': FieldValue.serverTimestamp(),
    });

    // 2. Create new alert in target hospital
    final newRef = _firestore
        .collection('hospitals')
        .doc(toHospitalId)
        .collection('alerts')
        .doc(alertId); // Keep same ID to track

    final newData = Map<String, dynamic>.from(alertData);
    newData['status'] = 'pending';
    newData['transferredFrom'] = fromHospitalId;
    newData['timestamp'] = FieldValue.serverTimestamp();
    newData['targetHospitalId'] = toHospitalId;

    batch.set(newRef, newData);

    // 3. Update global hospital_alerts so the new hospital sees it
    batch.update(
      _firestore.collection('hospital_alerts').doc(alertId),
      {
        'status': 'pending',
        'targetHospitalId': toHospitalId,
        'transferredFrom': fromHospitalId,
        'timestamp': FieldValue.serverTimestamp(),
      }
    );

    await batch.commit();
  }

  Future<void> triggerHospitalSOS({
    required String victimId,
    required String victimName,
    required double lat,
    required double lng,
    required String medicalInfo,
    String? phone,
    String? contacts,
    required String hospitalId,
    required String riskLevel,
  }) async {
    final alertData = {
      'userId': victimId, // Changed from victimId to userId for consistency
      'victimName': victimName,
      'location': GeoPoint(lat, lng),
      'medicalInfo': medicalInfo,
      'phone': phone,
      'contacts': contacts,
      'riskLevel': riskLevel,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'medical_sos',
      'targetHospitalId': hospitalId,
    };

    try {
      // 1. Add to global alerts with hospital target
      final alertDoc = await _firestore
          .collection('hospital_alerts')
          .add(alertData);

      debugPrint("Dispatched Hospital SOS to Hospital ID: $hospitalId");

      // 2. Also add to the specific hospital's alerts sub-collection if not 'all'
      if (hospitalId != 'all') {
        await _firestore
            .collection('hospitals')
            .doc(hospitalId)
            .collection('alerts')
            .doc(alertDoc.id)
            .set(alertData);
      }

      // 3. Add to user's alert history
      await _firestore
          .collection('users')
          .doc(victimId)
          .collection('alerts')
          .doc(alertDoc.id)
          .set({...alertData, 'hospitalId': hospitalId});
    } catch (e) {
      debugPrint("Error triggering hospital SOS: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getGlobalHospitalAlertsStream(String hospitalId) {
    return _firestore
        .collection('hospital_alerts')
        .where('targetHospitalId', whereIn: [hospitalId, 'unassigned', 'all'])
        .snapshots();
  }
}
