import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert_model.dart';
import 'alert_service.dart';
import 'police_service.dart';

class GeoService extends ChangeNotifier {
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  bool _isMonitoring = false;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  // Track the last zone entered to prevent spamming
  String? _lastZoneId;

  // Mock callback for when a risk zone is entered
  Function(String)? onRiskZoneEntered;

  // Expanded Risk Zones
  final List<Map<String, dynamic>> riskZones = [
    {
      "id": "military_zone",
      "name": "Restricted military zone",
      "center": LatLng(13.0827, 80.2707),
      "radius": 500,
      "severity": AlertSeverity.extreme,
    },
    {
      "id": "landslide_area",
      "name": "Landslide-prone hill area",
      "center": LatLng(13.0900, 80.2800),
      "radius": 300,
      "severity": AlertSeverity.high,
    },
    {
      "id": "wildlife_forest",
      "name": "Wildlife-risk forest zone",
      "center": LatLng(13.0700, 80.2600),
      "radius": 400,
      "severity": AlertSeverity.medium,
    }
  ];

  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  void startMonitoring() async {
    if (_isMonitoring) return;
    
    bool hasPermission = await checkPermissions();
    if (!hasPermission) return;

    _isMonitoring = true;
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      notifyListeners();

      // Live Track Victim: Update active alert location in Firestore
      final activeAlertId = AlertService().activeAlertId;
      if (activeAlertId != null) {
        PoliceService().updateAlertLocation(
          activeAlertId,
          lat: position.latitude,
          lng: position.longitude,
          userId: FirebaseAuth.instance.currentUser?.uid,
        );
      }

      _checkRiskZones(position);
    });
  }

  void _checkRiskZones(Position position) {
    bool inAnyZone = false;
    for (var zone in riskZones) {
      final center = zone["center"] as LatLng;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        center.latitude,
        center.longitude,
      );

      if (distance <= zone["radius"]) {
        inAnyZone = true;
        final zoneId = zone["id"] as String;
        
        if (_lastZoneId != zoneId) {
          _lastZoneId = zoneId;
          final name = zone["name"] as String;
          final severity = zone["severity"] as AlertSeverity;
          
          // Add to local AlertService
          AlertService().addAlert(
            title: name,
            description: "Entered designated risk area. Exercise caution.",
            severity: severity,
            lat: position.latitude,
            lng: position.longitude,
            notifyPolice: severity == AlertSeverity.extreme || severity == AlertSeverity.high,
          );

          onRiskZoneEntered?.call(name);
        }
        break; // Only trigger one zone at a time
      }
    }
    if (!inAnyZone) {
      _lastZoneId = null;
    }
  }

  void stopMonitoring() {
    _positionStream?.cancel();
    _isMonitoring = false;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
