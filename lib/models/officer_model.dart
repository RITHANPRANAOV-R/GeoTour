import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerModel {
  final String uid;
  final String name;
  final String badgeNumber;
  final String rank;
  final String station;
  final String division;
  final String personalPhone;
  final bool isAvailable;
  final String status;
  final GeoPoint? location;
  final double? distance;

  OfficerModel({
    required this.uid,
    required this.name,
    required this.badgeNumber,
    required this.rank,
    required this.station,
    required this.division,
    required this.personalPhone,
    required this.isAvailable,
    required this.status,
    this.location,
    this.distance,
  });

  factory OfficerModel.fromFirestore(
    DocumentSnapshot doc, {
    GeoPoint? userLocation,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    GeoPoint? officerLocation = data['location'] as GeoPoint?;
    double? distance;

    if (userLocation != null && officerLocation != null) {
      // Basic distance calculation placeholder if needed,
      // but usually done via Geolocator in UI or filter
    }

    return OfficerModel(
      uid: doc.id,
      name: data['name'] ?? 'Officer',
      badgeNumber: data['badgeNumber'] ?? 'N/A',
      rank: data['rank'] ?? '',
      station: data['station'] ?? '',
      division: data['division'] ?? '',
      personalPhone: data['personalPhone'] ?? '',
      isAvailable: data['isAvailable'] ?? false,
      status: data['status'] ?? 'offline',
      location: officerLocation,
      distance: distance,
    );
  }
}
