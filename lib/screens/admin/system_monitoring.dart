import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/admin_api_service.dart';

class SystemMonitoringScreen extends StatefulWidget {
  const SystemMonitoringScreen({super.key});

  @override
  State<SystemMonitoringScreen> createState() => _SystemMonitoringScreenState();
}

class _SystemMonitoringScreenState extends State<SystemMonitoringScreen> {
  final AdminAPIService _apiService = AdminAPIService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  dynamic _wsChannel;
  final MapController _mapController = MapController();
  StreamSubscription? _firestoreSub;
  StreamSubscription? _policeFirestoreSub;
  StreamSubscription? _medicalFirestoreSub;
  
  // Storage for merged data sources
  List<dynamic> _touristUsers = [];
  List<dynamic> _policeUsers = [];
  List<dynamic> _medicalUsers = [];
  
  String _activeFilter = "All";
  final List<String> _filters = ["All", "Tourists", "Police", "Medical"];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _connectWebSocket();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getMonitorData();
      final List<dynamic> newTourists = [];
      final List<dynamic> newPolice = [];
      final List<dynamic> newMedical = [];

      for (var user in data) {
        final role = user['activeRole']?.toString().toLowerCase();
        user['latitude'] = _extractLat(user);
        user['longitude'] = _extractLng(user);

        if (role == 'police') {
          newPolice.add(user);
        } else if (role == 'medical' || role == 'hospital') {
          newMedical.add(user);
        } else {
          user['activeRole'] = 'tourist';
          newTourists.add(user);
        }
      }

      _touristUsers = newTourists;
      _policeUsers = newPolice;
      _medicalUsers = newMedical;
      _updateUsersList();
    } catch (e) {
      debugPrint("Error fetching initial data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    _startFirestoreMonitoring();
  }

  void _updateUsersList() {
    if (!mounted) return;
    setState(() {
      _users = [..._touristUsers, ..._policeUsers, ..._medicalUsers];
    });
  }

  // Extract lat from either a GeoPoint 'location' field or flat 'latitude' field
  double _extractLat(dynamic data) {
    if (data == null) return 13.0827;
    final loc = data['location'];
    if (loc is GeoPoint) return loc.latitude;
    
    var lat = data['latitude'];
    if (lat == null) return 13.0827;
    if (lat is String) return double.tryParse(lat) ?? 13.0827;
    if (lat is num) return lat.toDouble();
    return 13.0827;
  }

  double _extractLng(dynamic data) {
    if (data == null) return 80.2707;
    final loc = data['location'];
    if (loc is GeoPoint) return loc.longitude;
    
    var lng = data['longitude'];
    if (lng == null) return 80.2707;
    if (lng is String) return double.tryParse(lng) ?? 80.2707;
    if (lng is num) return lng.toDouble();
    return 80.2707;
  }

  void _startFirestoreMonitoring() {
    // Cancel any previous subscriptions first
    _firestoreSub?.cancel();
    _policeFirestoreSub?.cancel();
    _medicalFirestoreSub?.cancel();

    // Listen to tourists (users collection) — exclude responders who have their own collections
    _firestoreSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _touristUsers = snapshot.docs
          .where((doc) {
            final role = doc.data()['activeRole']?.toString().toLowerCase() ?? 'tourist';
            return role == 'tourist' || role == '';
          })
          .map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'name': data['name'] ?? data['username'] ?? data['displayName'] ?? 'Tourist',
              'latitude': _extractLat(data),
              'longitude': _extractLng(data),
              'status': data['status'] ?? 'Stable',
              'activeRole': 'tourist',
            };
          })
          .toList();
      _updateUsersList();
      _fitBounds();
    });

    // Listen to police officers (police collection)
    _policeFirestoreSub = FirebaseFirestore.instance
        .collection('police')
        .snapshots()
        .listen((snapshot) {
      _policeUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? data['officerName'] ?? data['displayName'] ?? 'Officer',
          'latitude': _extractLat(data),
          'longitude': _extractLng(data),
          'status': data['status'] ?? 'available',
          'activeRole': 'police',
        };
      }).toList();
      _updateUsersList();
      _fitBounds();
    });

    // Listen to medical staff (medical collection)
    _medicalFirestoreSub = FirebaseFirestore.instance
        .collection('medical')
        .snapshots()
        .listen((snapshot) {
      _medicalUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? data['hospitalName'] ?? data['displayName'] ?? 'Medical Staff',
          'latitude': _extractLat(data),
          'longitude': _extractLng(data),
          'status': data['status'] ?? 'available',
          'activeRole': 'medical',
        };
      }).toList();
      _updateUsersList();
      _fitBounds();
    });
  }

  void _fitBounds() {
    final filteredUsers = _getFilteredUsers();
    if (filteredUsers.isEmpty) return;
    
    try {
      final points = filteredUsers
          .where((u) =>
              (u['latitude'] as num).toDouble() != 13.0827 || 
              (u['longitude'] as num).toDouble() != 80.2707) // skip defaults
          .map((u) => LatLng(
                (u['latitude'] as num).toDouble(),
                (u['longitude'] as num).toDouble(),
              ))
          .toList();

      if (points.isEmpty) return;

      if (points.length == 1) {
        _mapController.move(points.first, 14.0);
      } else {
        double minLat = points[0].latitude;
        double maxLat = points[0].latitude;
        double minLng = points[0].longitude;
        double maxLng = points[0].longitude;

        for (var p in points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }

        final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
        final latSpan = maxLat - minLat;
        final lngSpan = maxLng - minLng;
        final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;
        
        double zoom = 13.0;
        if (maxSpan > 1.0) {
          zoom = 7.0;
        } else if (maxSpan > 0.5) {
          zoom = 9.0;
        } else if (maxSpan > 0.1) {
          zoom = 11.0;
        } else if (maxSpan > 0.01) {
          zoom = 13.0;
        } else {
          zoom = 14.5;
        }

        _mapController.move(center, zoom);
      }
    } catch (e) {
      debugPrint("Error fitting bounds: $e");
    }
  }

  void _connectWebSocket() {
    try {
      _wsChannel = _apiService.connectToMonitorWS();
      _wsChannel?.stream.listen((message) {
        final data = json.decode(message);
        if (data is List) {
          final List<dynamic> newTourists = [];
          final List<dynamic> newPolice = [];
          final List<dynamic> newMedical = [];

          for (var user in data) {
            user['latitude'] = _extractLat(user);
            user['longitude'] = _extractLng(user);
            
            final role = user['activeRole']?.toString().toLowerCase();
            if (role == 'police') {
              newPolice.add(user);
            } else if (role == 'medical' || role == 'hospital') {
              newMedical.add(user);
            } else {
              user['activeRole'] = 'tourist';
              newTourists.add(user);
            }
          }

          _touristUsers = newTourists;
          _policeUsers = newPolice;
          _medicalUsers = newMedical;
        } else if (data is Map<String, dynamic>) {
          data['latitude'] = _extractLat(data);
          data['longitude'] = _extractLng(data);
          
          final String role = data['activeRole']?.toString().toLowerCase() ?? 'tourist';

          if (role == 'police') {
            final idx = _policeUsers.indexWhere((u) => u['uid'] == data['uid']);
            if (idx != -1) {
              _policeUsers[idx] = data;
            } else {
              _policeUsers.add(data);
            }
          } else if (role == 'medical' || role == 'hospital') {
            final idx = _medicalUsers.indexWhere((u) => u['uid'] == data['uid']);
            if (idx != -1) {
              _medicalUsers[idx] = data;
            } else {
              _medicalUsers.add(data);
            }
          } else {
            data['activeRole'] = 'tourist';
            final idx = _touristUsers.indexWhere((u) => u['uid'] == data['uid']);
            if (idx != -1) {
              _touristUsers[idx] = data;
            } else {
              _touristUsers.add(data);
            }
          }
        }
        _updateUsersList();
      }, onError: (err) {
        debugPrint("WebSocket Error: $err");
      });
    } catch (e) {
      debugPrint("WebSocket connection failed: $e");
    }
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _firestoreSub?.cancel();
    _policeFirestoreSub?.cancel();
    _medicalFirestoreSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "System Monitoring",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _fetchInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                _buildMapPlaceholder(),
                Expanded(
                  child: _getFilteredUsers().isEmpty
                      ? const Center(
                          child: Text("No tracking data matches filter."),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _getFilteredUsers().length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = _getFilteredUsers()[index];
                            final bool isDanger =
                                user['status']?.toString().toLowerCase() ==
                                    "in danger" ||
                                user['status']?.toString().toLowerCase() ==
                                    "sos";
                            final bool isPolice =
                                user['activeRole']?.toString() == 'police';
                            final bool isMedical =
                                user['activeRole']?.toString() == 'medical';

                            // Role-based colors
                            final Color roleColor = isDanger
                                ? Colors.red
                                : (isPolice
                                    ? Colors.blue
                                    : (isMedical ? Colors.orange : Colors.green));

                            final IconData roleIcon = isDanger
                                ? Icons.warning_rounded
                                : (isPolice
                                    ? Icons.local_police_rounded
                                    : (isMedical
                                        ? Icons.medical_services_rounded
                                        : Icons.person_rounded));

                            final String roleLabel = isPolice
                                ? 'Police Officer'
                                : (isMedical ? 'Medical Staff' : 'Tourist');

                            return Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFFAFAFA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDanger
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : const Color(0xFFF1F1F1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.015,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    roleIcon,
                                    color: roleColor,
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Unknown User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      roleLabel,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Lat: ${user['latitude']}, Lon: ${user['longitude']}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDanger
                                        ? const Color(0xFFFF3B30)
                                        : roleColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user['status'] ?? 'Stable',
                                    style: TextStyle(
                                      color: isDanger
                                          ? Colors.white
                                          : roleColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<dynamic> _getFilteredUsers() {
    if (_activeFilter == "Tourists") {
      return _users.where((u) => u['activeRole'] == 'tourist').toList();
    } else if (_activeFilter == "Police") {
      return _users.where((u) => u['activeRole'] == 'police').toList();
    } else if (_activeFilter == "Medical") {
      return _users.where((u) => u['activeRole'] == 'medical').toList();
    }
    return _users;
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final bool isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() => _activeFilter = filter);
              _fitBounds();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isActive ? Colors.black : Colors.grey.shade300,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    final filteredUsers = _getFilteredUsers();
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(13.0827, 80.2707),
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geotour.app',
            ),
            MarkerLayer(
              markers: filteredUsers
                  .where((u) => u['latitude'] != null && u['longitude'] != null)
                  .map((user) {
                final status = user['status']?.toString().toLowerCase() ?? '';
                final bool isSOS = status == 'sos' || status == 'in danger';
                final isPolice = user['activeRole'] == 'police';
                final isMedical = user['activeRole'] == 'medical';
                
                double lat = (user['latitude'] as num).toDouble();
                double lng = (user['longitude'] as num).toDouble();
                
                final int userIndex = filteredUsers.indexOf(user);
                if (userIndex > 0) {
                   lat += (userIndex % 10) * 0.0001;
                   lng += (userIndex % 10) * 0.0001;
                }

                final Color markerColor = isSOS 
                    ? Colors.red 
                    : (isPolice ? Colors.blue : (isMedical ? Colors.orange : Colors.green));
                
                final IconData markerIcon = isPolice 
                    ? Icons.local_police 
                    : (isMedical ? Icons.medical_services_rounded : Icons.location_on);

                return Marker(
                  key: ValueKey(user['uid'] ?? user['id'] ?? 'user_$userIndex'),
                  point: LatLng(lat, lng),
                  width: 45,
                  height: 45,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${user['name']} (${user['activeRole']})"),
                          backgroundColor: markerColor,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSOS)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Icon(
                          markerIcon,
                          color: markerColor,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
