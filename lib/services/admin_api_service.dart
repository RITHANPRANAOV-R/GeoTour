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
      final response = await http.get(Uri.parse("$baseUrl/monitor"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      // Falling back to /users as requested if /monitor is not available
      final userResponse = await http.get(Uri.parse("$baseUrl/users"));
      if (userResponse.statusCode == 200) {
        return json.decode(userResponse.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching monitor data: $e");
      return [];
    }
  }

  WebSocketChannel connectToMonitorWS() {
    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  // --- Geo-Fence Zones ---
  Future<List<dynamic>> getZones() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/zones"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addZone(Map<String, dynamic> zone) async {
    try {
      // 1. Update Backend API
      final response = await http.post(
        Uri.parse("$baseUrl/zones"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(zone),
      );

      // 2. Update Firebase Firestore for real-time mobile tracking
      await _firestore.collection('zones').add({
        ...zone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding zone: $e");
      return false;
    }
  }

  Future<bool> deleteZone(String id) async {
    try {
      // 1. Update Backend API
      await http.delete(Uri.parse("$baseUrl/zones/$id"));

      // 2. Update Firebase Firestore
      // Note: We'd need the Firestore document ID to delete specifically. 
      // For now, we'll delete by name if id is a mock ID, or implement exact ID sync.
      final query = await _firestore.collection('zones').where('id', isEqualTo: id).get();
      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // --- User Management ---
  Future<List<dynamic>> getUsers() async {
    List<dynamic> allUsers = [];

    // 1. Fetch from Local REST Backend
    try {
      final response = await http.get(Uri.parse("$baseUrl/users"));
      if (response.statusCode == 200) {
        allUsers.addAll(json.decode(response.body));
      }
    } catch (e) {
      debugPrint("REST Backend unreachable: $e");
    }

    // 2. Fetch from Firebase Firestore (Main App Database)
    try {
      final snapshot = await _firestore.collection('users').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Check if user already exists in list (to avoid duplicates)
        bool exists = allUsers.any((u) => u['id'] == doc.id || u['email'] == data['email']);
        if (!exists) {
          allUsers.add({
            'id': doc.id,
            'name': data['name'] ?? data['email']?.split('@')[0] ?? 'User',
            'email': data['email'],
            'role': data['activeRole'] ?? (data['roles'] is List ? data['roles'][0] : 'tourist'),
          });
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
      final response = await http.post(
        Uri.parse("$baseUrl/users"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(user),
      );

      // 2. Update Firebase Firestore
      String role = user['role'] ?? 'tourist';
      String collection = role == 'admin' ? 'admins' : (role == 'police' ? 'police' : 'tourist');
      
      await _firestore.collection(collection).add({
        ...user,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editUser(String id, Map<String, dynamic> user) async {
    try {
      // 1. Update Backend API
      final response = await http.put(
        Uri.parse("$baseUrl/users/$id"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(user),
      );

      // 2. Update Firebase Firestore
      final query = await _firestore.collection('tourist').where('id', isEqualTo: id).get();
      for (var doc in query.docs) {
        await doc.reference.update(user);
      }

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      // 1. Update Backend API
      await http.delete(Uri.parse("$baseUrl/users/$id"));

      // 2. Update Firebase Firestore
      final collections = ['tourist', 'police', 'admins', 'medical'];
      for (var col in collections) {
        final query = await _firestore.collection(col).where('id', isEqualTo: id).get();
        for (var doc in query.docs) {
          await doc.reference.delete();
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Incident Logs ---
  Future<List<dynamic>> getIncidents() async {
    List<dynamic> allIncidents = [];

    // 1. Fetch from Local REST Backend
    try {
      final response = await http.get(Uri.parse("$baseUrl/incidents"));
      if (response.statusCode == 200) {
        allIncidents.addAll(json.decode(response.body));
      }
    } catch (e) {
      debugPrint("REST Backend unreachable: $e");
    }

    // 2. Fetch from Firebase Firestore (Police Mission Logs)
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
          'timestamp': data['timestamp']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'officer': data['officerName'] ?? 'System',
        });
      }
    } catch (e) {
      debugPrint("Error fetching Firestore incidents: $e");
    }

    return allIncidents;
  }
}
