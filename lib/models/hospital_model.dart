import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalModel {
  final String uid;
  final String name;
  final String category;
  final String emergencyPhone;
  final String ambulanceNumber;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // Calculated distance from current user

  HospitalModel({
    required this.uid,
    required this.name,
    required this.category,
    required this.emergencyPhone,
    required this.ambulanceNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance = 0.0,
  });

  factory HospitalModel.fromFirestore(DocumentSnapshot doc, {double userLat = 0, double userLng = 0}) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Simple Euclidean distance or just 0 for now if not calculated
    return HospitalModel(
      uid: doc.id,
      name: data['hospitalName'] ?? 'Unknown Hospital',
      category: data['category'] ?? 'General',
      emergencyPhone: data['emergencyPhone'] ?? '',
      ambulanceNumber: data['ambulanceNumber'] ?? '',
      address: data['fullAddress'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
    );
  }
}
