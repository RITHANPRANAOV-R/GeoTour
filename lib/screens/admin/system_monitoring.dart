import 'dart:convert';
import 'package:flutter/material.dart';
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
          // Assuming data is a single user update or full list
          if (data is List) {
            _users = data;
          } else {
            // Update individual user in list if found
            int index = _users.indexWhere((u) => u['id'] == data['id']);
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
      appBar: AppBar(
        title: const Text("System Monitoring"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInitialData,
          )
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final bool isDanger = user['status']?.toString().toLowerCase() == "in danger";
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              color: isDanger ? Colors.red.shade50 : Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDanger ? Colors.red : Colors.green,
                                  child: Icon(
                                    isDanger ? Icons.warning_rounded : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Unknown User',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Lat: ${user['latitude']}, Lon: ${user['longitude']}",
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDanger ? Colors.red : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user['status'] ?? 'Stable',
                                    style: TextStyle(
                                      color: isDanger ? Colors.white : Colors.green.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Connecting to GPS Network...",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Map API integration pending",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
