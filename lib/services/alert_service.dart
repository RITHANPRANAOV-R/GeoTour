import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert_model.dart';
import 'police_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class AlertService extends ChangeNotifier {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final List<AlertModel> _alerts = [];
  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  StreamSubscription? _userAlertsSub;
  StreamSubscription? _authSub;
  String? _activeAlertId;

  String? get activeAlertId => _activeAlertId;

  void initialize() {
    // Listen for auth state changes to start/stop syncing
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startSync(user.uid);
      } else {
        _stopSync();
      }
    });

    // Initial check
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      _startSync(currentUser.uid);
    }
  }

  StreamSubscription? _hospitalAlertsSub;

  void _startSync(String uid) {
    _userAlertsSub?.cancel();
    _userAlertsSub = PoliceService().getUserAlertsStream(uid).listen((snapshot) {
      _processAlerts(snapshot, 'police');
    });

    _hospitalAlertsSub?.cancel();
    _hospitalAlertsSub = FirebaseFirestore.instance
        .collection('hospital_alerts')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _processAlerts(snapshot, 'medical');
    });
  }

  void _processAlerts(QuerySnapshot snapshot, String type) {
    // Merge or handle alerts
    // For simplicity, we'll maintain a list that distinguishes by type if needed
    // But for the listener to work, we need to clear and rebuild carefully
    // Actually, let's keep them in the same _alerts list but with metadata
    
    // Instead of clear(), we find/update/add
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final alert = AlertModel(
        id: doc.id,
        title: data['threat'] ?? data['victimName'] ?? "Alert",
        description: data['medicalInfo'] ?? "Emergency SOS",
        timeAgo: _formatTimestamp(data['timestamp']),
        severity: _parseSeverity(data['riskLevel']),
        lat: (data['location'] as GeoPoint?)?.latitude ?? 0.0,
        lng: (data['location'] as GeoPoint?)?.longitude ?? 0.0,
        status: data['status'] ?? 'pending',
      );
      
      final index = _alerts.indexWhere((a) => a.id == doc.id);
      if (index >= 0) {
        _alerts[index] = alert;
      } else {
        _alerts.add(alert);
      }
    }
    notifyListeners();
  }

  void _stopSync() {
    _userAlertsSub?.cancel();
    _hospitalAlertsSub?.cancel();
    _alerts.clear();
    notifyListeners();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    final dt = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    return "${diff.inHours}h ago";
  }

  AlertSeverity _parseSeverity(String? level) {
    switch (level?.toUpperCase()) {
      case 'EXTREME':
        return AlertSeverity.extreme;
      case 'HIGH':
        return AlertSeverity.high;
      case 'MEDIUM':
        return AlertSeverity.medium;
      default:
        return AlertSeverity.low;
    }
  }

  Future<String?> addAlert({
    required String title,
    required String description,
    required AlertSeverity severity,
    required double lat,
    required double lng,
    bool notifyPolice = false,
  }) async {
    final user = AuthService().currentUser;
    final userId = user?.uid;
    String userName = user?.displayName ?? "Tourist";
    String? phone;
    String? contacts;
    String? touristId;

    if (userId != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>;
        userName = data['name'] ?? userName;
        phone = data['phone'];
        touristId = data['touristId'];
        if (data.containsKey('emergencyContacts')) {
          final ec = data['emergencyContacts'] as List<dynamic>;
          contacts = ec
              .map((e) => "${e['name']} (${e['relation']}): ${e['phone']}")
              .join("\n");
        }
      }
    }

    final alertId = await PoliceService().triggerAlert(
      name: userName,
      threat: title,
      riskLevel: severity.name.toUpperCase(),
      lat: lat,
      lng: lng,
      userId: userId,
      phone: phone,
      contacts: contacts,
      touristId: touristId,
    );

    // Note: No need to manually insert to _alerts here because
    // the Firestore listener in initialize() will pick it up automatically.
    _activeAlertId = alertId;

    if (alertId != null) {
      NotificationService().showNotification(
        id: alertId.hashCode,
        title: "🚨 Alert Triggered: $title",
        body: description,
      );
    }
    return alertId;
  }

  void setActiveAlertId(String? id) {
    _activeAlertId = id;
    notifyListeners();
  }

  void stopSync() {
    _userAlertsSub?.cancel();
  }

  void clearAlerts() {
    _alerts.clear();
    NotificationService().clearBadge();
    notifyListeners();
  }
}
