import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class GeofenceManagementScreen extends StatefulWidget {
  const GeofenceManagementScreen({super.key});

  @override
  State<GeofenceManagementScreen> createState() => _GeofenceManagementScreenState();
}

class _GeofenceManagementScreenState extends State<GeofenceManagementScreen> {
  final AdminAPIService _apiService = AdminAPIService();
  List<dynamic> _zones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getZones();
    setState(() {
      _zones = data;
      _isLoading = false;
    });
  }

  void _showAddZoneDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final radiusController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Geo-Fence Zone"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Zone Name")),
              TextField(controller: latController, decoration: const InputDecoration(labelText: "Latitude"), keyboardType: TextInputType.number),
              TextField(controller: lonController, decoration: const InputDecoration(labelText: "Longitude"), keyboardType: TextInputType.number),
              TextField(controller: radiusController, decoration: const InputDecoration(labelText: "Radius (meters)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> newZone = {
                "name": nameController.text,
                "latitude": double.tryParse(latController.text) ?? 0.0,
                "longitude": double.tryParse(lonController.text) ?? 0.0,
                "radius": double.tryParse(radiusController.text) ?? 100.0,
              };
              bool success = await _apiService.addZone(newZone);
              if (success && mounted) {
                Navigator.pop(context);
                _fetchZones();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geo-Fence Management")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMapPlaceholder(),
                Expanded(
                  child: _zones.isEmpty
                      ? const Center(child: Text("No zones found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _zones.length,
                          itemBuilder: (context, index) {
                            final zone = _zones[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.location_on, color: Colors.blue),
                                ),
                                title: Text(zone['name'] ?? 'Unnamed Zone', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Lat: ${zone['latitude']}, Lon: ${zone['longitude']}\nRadius: ${zone['radius']}m"),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    bool success = await _apiService.deleteZone(zone['id'].toString());
                                    if (success && mounted) {
                                      _fetchZones();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddZoneDialog,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text("Add Zone"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.08)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading Zone Geometries...",
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Map SDK is initializing",
              style: TextStyle(
                color: Colors.blue.shade400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
