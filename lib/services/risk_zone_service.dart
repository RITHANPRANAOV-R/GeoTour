import 'package:cloud_firestore/cloud_firestore.dart';

class RiskZoneService {
  static final RiskZoneService _instance = RiskZoneService._internal();
  factory RiskZoneService() => _instance;
  RiskZoneService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live stream of all risk zones from Firestore.
  Stream<List<Map<String, dynamic>>> get riskZonesStream => _db
      .collection('riskZones')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList(),
      );

  /// One-time fetch of all risk zones.
  Future<List<Map<String, dynamic>>> fetchZones() async {
    final snap = await _db
        .collection('riskZones')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Add a new risk zone to Firestore.
  Future<void> addRiskZone({
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String severity, // 'extreme' | 'high' | 'medium' | 'low'
    required String type, // 'risk' | 'restricted'
    int? maxTime, // in minutes, only for 'risk'
  }) async {
    await _db.collection('riskZones').add({
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'severity': severity,
      'type': type,
      'maxTime': maxTime,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a risk zone by its Firestore document ID.
  Future<void> deleteRiskZone(String id) async {
    await _db.collection('riskZones').doc(id).delete();
  }

  /// Update a risk zone.
  Future<void> updateRiskZone(
    String id, {
    String? name,
    double? radius,
    String? severity,
    String? type,
    int? maxTime,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (radius != null) updates['radius'] = radius;
    if (severity != null) updates['severity'] = severity;
    if (type != null) updates['type'] = type;
    if (maxTime != null) updates['maxTime'] = maxTime;
    if (updates.isNotEmpty) {
      await _db.collection('riskZones').doc(id).update(updates);
    }
  }
}
