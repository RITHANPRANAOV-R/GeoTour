import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _connectWebSocket();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getMonitorData();
    setState(() {
      _users = data;
      _isLoading = false;
    });
  }

  void _connectWebSocket() {
    try {
      _wsChannel = _apiService.connectToMonitorWS();
      _wsChannel?.stream.listen((message) {
        final data = json.decode(message);
        setState(() {
          if (data is List) {
            _users = data;
          } else if (data is Map<String, dynamic>) {
            final index = _users.indexWhere((u) => u['uid'] == data['uid']);
            if (index != -1) {
              _users[index] = data;
            } else {
              _users.add(data);
            }
          }
        });
      });
    } catch (e) {
      debugPrint("WebSocket Error: $e");
    }
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
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
                _buildMapPlaceholder(),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text("No tracking data available."))
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _users.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final bool isDanger =
                                user['status']?.toString().toLowerCase() ==
                                "in danger";

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
                                      color: Colors.black.withValues(alpha: 0.015),
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
                                    color:
                                        (isDanger ? Colors.red : Colors.green)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isDanger
                                        ? Icons.warning_rounded
                                        : Icons.person_rounded,
                                    color: isDanger ? Colors.red : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Unknown User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Lat: ${user['latitude']}, Lon: ${user['longitude']}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDanger
                                        ? const Color(0xFFFF3B30)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user['status'] ?? 'Stable',
                                    style: TextStyle(
                                      color: isDanger
                                          ? Colors.white
                                          : const Color(0xFF34C759),
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

  Widget _buildMapPlaceholder() {
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
              markers: _users.map((user) {
                final isDanger = user['status']?.toString().toLowerCase() == 'sos';
                return Marker(
                  point: LatLng(
                    (user['latitude'] as num).toDouble(),
                    (user['longitude'] as num).toDouble(),
                  ),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: isDanger ? Colors.red : Colors.blue,
                    size: 30,
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
