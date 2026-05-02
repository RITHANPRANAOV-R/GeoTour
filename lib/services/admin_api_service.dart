import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAPIService {
  final String baseUrl = "http://localhost:8000";
  final String wsUrl = "ws://localhost:8000/ws/monitor";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- System Monitoring ---
  Future<List<dynamic>> getMonitorData() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/monitor"))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Monitor REST API failed: $e");
    }

    // Falling back to tracking data from Firestore if available
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? data['username'] ?? 'User',
          'latitude': data['latitude'] ?? 13.0827,
          'longitude': data['longitude'] ?? 80.2707,
          'status': data['status'] ?? 'Stable',
          'activeRole': data['activeRole'] ?? 'tourist',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  WebSocketChannel connectToMonitorWS() {
    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  // --- Geo-Fence Zones ---
  Future<List<dynamic>> getZones() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/zones"))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Zones REST API failed: $e");
    }

    // Fallback to Firestore
    try {
      final snapshot = await _firestore.collection('riskZones').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addZone(Map<String, dynamic> zone) async {
    try {
      // 1. Update Backend API (Optional)
      try {
        await http
            .post(
              Uri.parse("$baseUrl/zones"),
              headers: {"Content-Type": "application/json"},
              body: json.encode(zone),
            )
            .timeout(const Duration(seconds: 1));
      } catch (_) {}

      // 2. Update Firebase Firestore
      await _firestore.collection('riskZones').add({
        ...zone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error adding zone: $e");
      return false;
    }
  }

  Future<bool> deleteZone(String id) async {
    try {
      // 1. Update Backend API
      try {
        await http
            .delete(Uri.parse("$baseUrl/zones/$id"))
            .timeout(const Duration(seconds: 1));
      } catch (_) {}

      // 2. Update Firebase Firestore
      await _firestore.collection('riskZones').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- User Management ---
  Future<List<dynamic>> getUsers() async {
    List<dynamic> allUsers = [];

    // 1. Try Local REST Backend
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/users"))
          .timeout(const Duration(milliseconds: 800));
      if (response.statusCode == 200) {
        allUsers.addAll(json.decode(response.body));
      }
    } catch (e) {
      debugPrint("REST Backend unreachable: $e");
    }

    // 2. Fetch from Firebase Firestore (Source of Truth)
    try {
      final snapshot = await _firestore.collection('users').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        int existingIndex = allUsers.indexWhere(
          (u) => u['id'] == doc.id || u['email'] == data['email'],
        );

        final userObj = {
          'id': doc.id,
          'name': data['name'] ?? data['email']?.split('@')[0] ?? 'User',
          'email': data['email'],
          'role':
              data['activeRole'] ??
              (data['roles'] is List && (data['roles'] as List).isNotEmpty
                  ? data['roles'][0]
                  : 'tourist'),
          'isBlocked': data['isBlocked'] ?? false,
        };

        if (existingIndex != -1) {
          allUsers[existingIndex] = userObj;
        } else {
          allUsers.add(userObj);
        }
      }
    } catch (e) {
      debugPrint("Error fetching Firestore users: $e");
    }

    return allUsers;
  }

  Future<bool> addUser(Map<String, dynamic> user) async {
    try {
      // 1. Update Backend API
      try {
        await http
            .post(
              Uri.parse("$baseUrl/users"),
              headers: {"Content-Type": "application/json"},
              body: json.encode(user),
            )
            .timeout(const Duration(seconds: 1));
      } catch (_) {}

      // 2. Update Firebase Firestore
      String role = user['role'] ?? 'tourist';
      String roleCollection =
          role == 'admin'
              ? 'admins'
              : (role == 'police'
                  ? 'police'
                  : (role == 'medical' ? 'medical' : 'tourists'));

      final userRef = _firestore.collection('users').doc();
      final batch = _firestore.batch();

      batch.set(userRef, {
        'name': user['name'],
        'email': user['email'],
        'activeRole': role,
        'roles': [role],
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_firestore.collection(roleCollection).doc(userRef.id), {
        ...user,
        'id': userRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Error adding user: $e");
      return false;
    }
  }

  Future<bool> editUser(String id, Map<String, dynamic> user) async {
    try {
      // 1. Update Backend API
      try {
        await http
            .put(
              Uri.parse("$baseUrl/users/$id"),
              headers: {"Content-Type": "application/json"},
              body: json.encode(user),
            )
            .timeout(const Duration(seconds: 1));
      } catch (_) {}

      // 2. Update Firebase Firestore
      await _firestore.collection('users').doc(id).update({
        'name': user['name'],
        'email': user['email'],
        'activeRole': user['role'],
      });

      final collections = ['tourists', 'police', 'admins', 'medical'];
      for (var col in collections) {
        try {
          await _firestore.collection(col).doc(id).update(user);
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint("Error editing user: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      // 1. Update Backend API
      try {
        await http
            .delete(Uri.parse("$baseUrl/users/$id"))
            .timeout(const Duration(seconds: 1));
      } catch (_) {}

      // 2. Update Firebase Firestore
      await _firestore.collection('users').doc(id).delete();

      final collections = ['tourists', 'police', 'admins', 'medical'];
      for (var col in collections) {
        try {
          await _firestore.collection(col).doc(id).delete();
        } catch (_) {}
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Incident Logs ---
  Future<List<dynamic>> getIncidents() async {
    List<dynamic> allIncidents = [];

    // 1. Fetch from Local REST Backend (with timeout)
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/incidents"))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        allIncidents.addAll(json.decode(response.body));
      }
    } catch (e) {
      debugPrint("REST Backend unreachable: $e");
    }

    // 2. Fetch from Firebase Firestore (Main App Database)
    try {
      final snapshot = await _firestore
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        allIncidents.add({
          'id': doc.id,
          'type': data['riskLevel'] ?? 'Notification',
          'user': data['victimName'] ?? 'Unknown User',
          'details': data['summary'] ?? 'N/A',
          'timestamp':
              data['timestamp'] is Timestamp
                  ? (data['timestamp'] as Timestamp).toDate().toIso8601String()
                  : DateTime.now().toIso8601String(),
          'officer': data['officerName'] ?? 'System',
        });
      }
    } catch (e) {
      debugPrint("Error fetching Firestore incidents: $e");
    }

    return allIncidents;
  }
}
