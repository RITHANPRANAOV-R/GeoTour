import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum TripStatus { notStarted, active, completed }

class TripModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String startLocation;
  final LatLng? startPoint;
  final String endLocation;
  final LatLng? endPoint;
  final List<String> stops;
  final List<LatLng> stopPoints;
  final DateTime startDate;
  final DateTime endDate;
  final TripStatus status;

  TripModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = "",
    required this.startLocation,
    this.startPoint,
    required this.endLocation,
    this.endPoint,
    this.stops = const [],
    this.stopPoints = const [],
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  int get durationInDays => endDate.difference(startDate).inDays;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'startLocation': startLocation,
      'startPoint': startPoint != null
          ? GeoPoint(startPoint!.latitude, startPoint!.longitude)
          : null,
      'endLocation': endLocation,
      'endPoint': endPoint != null
          ? GeoPoint(endPoint!.latitude, endPoint!.longitude)
          : null,
      'stops': stops,
      'stopPoints': stopPoints
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
    };
  }

  factory TripModel.fromFirestore(Map<String, dynamic> json, String id) {
    LatLng? parseLatLng(dynamic data) {
      if (data == null) return null;
      if (data is GeoPoint) {
        return LatLng(data.latitude, data.longitude);
      }
      // Fallback for legacy Map data
      if (data is Map) {
        return LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );
      }
      return null;
    }

    return TripModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startLocation: json['startLocation'] ?? '',
      startPoint: parseLatLng(json['startPoint']),
      endLocation: json['endLocation'] ?? '',
      endPoint: parseLatLng(json['endPoint']),
      stops: List<String>.from(json['stops'] ?? []),
      stopPoints: (json['stopPoints'] as List? ?? [])
          .map((p) => parseLatLng(p))
          .whereType<LatLng>()
          .toList(),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.notStarted,
      ),
    );
  }
}
