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

  Future<void> triggerHospitalSOS({
    required String victimId,
    required String victimName,
    required double lat,
    required double lng,
    required String medicalInfo,
    required String hospitalId,
    required String riskLevel,
  }) async {
    final alertData = {
      'victimId': victimId,
      'victimName': victimName,
      'location': GeoPoint(lat, lng),
      'medicalInfo': medicalInfo,
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

      // 2. Also add to the specific hospital's alerts sub-collection
      await _firestore
          .collection('hospitals')
          .doc(hospitalId)
          .collection('alerts')
          .doc(alertDoc.id)
          .set(alertData);

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
}
