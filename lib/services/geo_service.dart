import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import 'alert_service.dart';
import 'police_service.dart';
import 'risk_zone_service.dart';
import 'notification_service.dart';

enum LocationStatus {
  enabled,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class GeoService extends ChangeNotifier {
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  bool _isMonitoring = false;
  bool _isServiceEnabled = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  StreamSubscription<List<Map<String, dynamic>>>? _riskZonesSub;
  Position? _currentPosition;
  bool _isManualOverride = false;
  Timer? _manualCheckTimer;
  double _warningRange = 500.0; // Default warning range in meters

  bool get isServiceEnabled => _isServiceEnabled;

  // Tracking for proximity and time-in-zone
  String? _lastNearZoneId;
  DateTime? _zoneEntryTime;
  bool _sosTriggeredForCurrentZone = false;

  void overridePosition(LatLng point) {
    _isManualOverride = true;
    _currentPosition = Position(
      latitude: point.latitude,
      longitude: point.longitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    notifyListeners();
    _checkRiskZones(_currentPosition!);
    
    // Start periodic check for simulated position (for timers)
    _manualCheckTimer?.cancel();
    _manualCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isManualOverride && _currentPosition != null) {
        _checkRiskZones(_currentPosition!);
      }
    });
  }

  void resetManualOverride() {
    _isManualOverride = false;
    _currentPosition = null; // Clear spoofed position to force fresh fetch
    _manualCheckTimer?.cancel();
    checkPermissions(); // Re-verify hardware status
    notifyListeners();
  }

  void setManualOverrideStatus(bool status) {
    _isManualOverride = status;
    if (!status) {
      _currentPosition = null;
      checkPermissions();
    }
    notifyListeners();
  }

  Position? get currentPosition => _currentPosition;
  bool get isManualOverride => _isManualOverride;
  double get warningRange => _warningRange;

  void setWarningRange(double range) {
    _warningRange = range;
    notifyListeners();
  }

  // Track the last zone entered to prevent spamming
  String? _lastZoneId;

  // Mock callback for when a risk zone is entered
  Function(String)? onRiskZoneEntered;

  // Dynamic Risk Zones from Firestore
  List<Map<String, dynamic>> _riskZones = [];
  List<Map<String, dynamic>> get riskZones => _riskZones;

  Future<LocationStatus> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _isServiceEnabled = serviceEnabled;
    notifyListeners();

    if (!serviceEnabled) return LocationStatus.serviceDisabled;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationStatus.permissionDenied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.permissionDeniedForever;
    }

    return LocationStatus.enabled;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<LocationStatus> startMonitoring({bool forceRestart = false}) async {
    if (_isMonitoring && !forceRestart) return LocationStatus.enabled;

    final status = await checkPermissions();
    if (status != LocationStatus.enabled) return status;

    _isMonitoring = true;
    _isServiceEnabled = true;
    notifyListeners();

    // 1. Listen to service status changes to dynamically resume tracking
    _serviceStatusSub?.cancel();
    _serviceStatusSub = Geolocator.getServiceStatusStream().listen((status) {
      final bool enabled = status == ServiceStatus.enabled;
      if (enabled != _isServiceEnabled) {
        _isServiceEnabled = enabled;
        if (!_isServiceEnabled) {
          _currentPosition = null;
        } else if (_isMonitoring) {
          startMonitoring(forceRestart: true);
        }
        notifyListeners();
      }
    });

    // 2. Fetch current position once to "wake up" GPS and update status immediately
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _currentPosition = position;
      _isServiceEnabled = true;
      notifyListeners();
      _checkRiskZones(position);
    } catch (e) {
      debugPrint("Initial Position Fetch Error: $e");
    }

    // 3. Start listening to risk zones from Firestore
    _riskZonesSub?.cancel();
    _riskZonesSub = RiskZoneService().riskZonesStream.listen((zones) {
      _riskZones = zones.map((z) {
        return {
          ...z,
          'center': LatLng(z['latitude'] as double, z['longitude'] as double),
          'severity': _parseSeverity(z['severity']),
        };
      }).toList();
      notifyListeners();
    });

    // 4. Initialize Position Stream
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 30),
      ),
    ).listen((Position position) {
      if (!_isManualOverride) {
        _isServiceEnabled = true; // Heartbeat
        _currentPosition = position;
        notifyListeners();
        
        _checkRiskZones(position);
        
        // Sync location
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).catchError((e) => debugPrint("Firestore Sync Error: $e"));
        }

        // Live Track Victim
        final activeAlertId = AlertService().activeAlertId;
        if (activeAlertId != null) {
          PoliceService().updateAlertLocation(
            activeAlertId,
            lat: position.latitude,
            lng: position.longitude,
            userId: user?.uid,
          );
        }
      }
    }, onError: (e) {
      debugPrint("Position Stream Error: $e");
      _isServiceEnabled = false;
      notifyListeners();
    });

    return LocationStatus.enabled;
  }

  AlertSeverity _parseSeverity(dynamic severity) {
    if (severity is AlertSeverity) return severity;
    switch (severity.toString().toLowerCase()) {
      case 'extreme':
        return AlertSeverity.extreme;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      default:
        return AlertSeverity.medium;
    }
  }

  void _checkRiskZones(Position position) {
    bool inAnyZone = false;
    bool nearAnyZone = false;

    for (var zone in _riskZones) {
      final center = zone["center"] as LatLng;
      final radius = (zone["radius"] as num).toDouble();
      final zoneId = zone["id"] as String;
      final zoneType = zone["type"] ?? 'risk';
      final maxTime = (zone["maxTime"] ?? 30) as int; // minutes
      final name = zone["name"] as String;
      final severity = zone["severity"] as AlertSeverity;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        center.latitude,
        center.longitude,
      );

      // 1. Proximity Check (Warning)
      if (distance <= radius + _warningRange && distance > radius) {
        nearAnyZone = true;
        if (_lastNearZoneId != zoneId && _lastZoneId != zoneId) {
          _lastNearZoneId = zoneId;
          NotificationService().showNotification(
            id: zoneId.hashCode + 1,
            title: "⚠️ Proximity Warning",
            body: "You are approaching the $name $zoneType zone (${distance.toInt()}m away).",
          );
        }
      }

      // 2. Entry and Active Monitoring
      if (distance <= radius) {
        inAnyZone = true;
        
        // Just Entered
        if (_lastZoneId != zoneId) {
          _lastZoneId = zoneId;
          _zoneEntryTime = DateTime.now();
          _sosTriggeredForCurrentZone = false;
          _lastNearZoneId = null; // Clear near warning if we entered

          NotificationService().showNotification(
            id: zoneId.hashCode,
            title: zoneType == 'restricted' ? "🛑 RESTRICTED AREA" : "⚠️ RISK ZONE",
            body: "You have entered $name. ${zoneType == 'restricted' ? 'Immediate SOS triggered!' : 'Exercise caution.'}",
          );

          if (zoneType == 'restricted') {
            _triggerSOS(position, zone, "Restricted Zone Access");
            _sosTriggeredForCurrentZone = true;
          } else {
            // Log entry but don't SOS yet for 'risk' type
            AlertService().addAlert(
              title: "$name Entry",
              description: "Entered risk area. Timer started ($maxTime mins).",
              severity: severity,
              lat: position.latitude,
              lng: position.longitude,
              notifyPolice: false,
            );
          }
        } 
        
        // Already Inside - Check Timer for Risk Zones
        else if (zoneType == 'risk' && !_sosTriggeredForCurrentZone && _zoneEntryTime != null) {
          final timeSpent = DateTime.now().difference(_zoneEntryTime!).inMinutes;
          if (timeSpent >= maxTime) {
            _triggerSOS(position, zone, "Stay exceeded max time ($maxTime mins)");
            _sosTriggeredForCurrentZone = true;
          }
        }
        
        break; // Process one zone at a time
      }
    }

    if (!inAnyZone) {
      if (_lastZoneId != null) {
        // Just left a zone
        NotificationService().showNotification(
          id: 777,
          title: "Zone Exited",
          body: "You are now in a safe area.",
        );
      }
      _lastZoneId = null;
      _zoneEntryTime = null;
      _sosTriggeredForCurrentZone = false;
    }
    if (!nearAnyZone) {
      _lastNearZoneId = null;
    }
  }

  void _triggerSOS(Position position, Map<String, dynamic> zone, String reason) async {
    final name = zone["name"] as String;
    final severity = zone["severity"] as AlertSeverity;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? touristId;
      try {
        final profileDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (profileDoc.exists) {
          touristId = profileDoc.data()?['touristId'];
        }
      } catch (e) {
         debugPrint("Error fetching touristId for SOS: $e");
      }

      PoliceService().triggerPoliceSOS(
        lat: position.latitude,
        lng: position.longitude,
        victimId: user.uid,
        victimName: user.displayName ?? "Unknown Tourist",
        riskLevel: severity.name.toUpperCase(),
        threat: "Automated SOS ($reason): Tourist at $name",
        touristId: touristId,
      );

      NotificationService().showNotification(
        id: 911,
        title: "🚨 SOS BROADCASTED 🚨",
        body: "Emergency services have been notified of your location in $name.",
      );

      AlertService().addAlert(
        title: "SOS: $name",
        description: "$reason. Police alerted.",
        severity: AlertSeverity.extreme,
        lat: position.latitude,
        lng: position.longitude,
        notifyPolice: true,
      );
    }
    onRiskZoneEntered?.call(name);
  }

  void stopMonitoring() {
    _positionStream?.cancel();
    _riskZonesSub?.cancel();
    _isMonitoring = false;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
