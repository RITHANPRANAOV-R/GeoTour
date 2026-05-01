import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/risk_zone_service.dart';
import '../../widgets/premium_toast.dart';

class GeofenceManagementScreen extends StatefulWidget {
  const GeofenceManagementScreen({super.key});

  @override
  State<GeofenceManagementScreen> createState() =>
      _GeofenceManagementScreenState();
}

class _GeofenceManagementScreenState extends State<GeofenceManagementScreen> {
  final MapController _mapController = MapController();
  LatLng? _pickedPoint;
  final RiskZoneService _riskZoneService = RiskZoneService();

  void _onMapTap(TapPosition tapPos, LatLng point) {
    setState(() {
      _pickedPoint = point;
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _showAddZoneSheet() {
    if (_pickedPoint == null) {
      PremiumToast.show(
        context,
        title: "Point Not Selected",
        message: "Please tap on the map to pick a zone center.",
        type: ToastType.warning,
      );
      return;
    }

    final nameController = TextEditingController();
    final maxTimeController = TextEditingController(text: "30");
    double radius = 300.0;
    String severity = 'high';
    String zoneType = 'risk'; // 'risk' or 'restricted'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 32,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Finalize Risk Zone",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Zone Name",
                  hintText: "e.g., Landslide Hill, High Water Area",
                  prefixIcon: const Icon(Icons.label_important_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Radius: ${radius.toInt()} meters",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: radius,
                min: 100,
                max: 5000,
                divisions: 49,
                activeColor: Colors.black,
                onChanged: (val) => setSheetState(() => radius = val),
              ),
              const SizedBox(height: 16),
              const Text(
                "Zone Type",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'risk',
                    groupValue: zoneType,
                    onChanged: (val) => setSheetState(() => zoneType = val!),
                  ),
                  const Text("Risk", style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Radio<String>(
                    value: 'restricted',
                    groupValue: zoneType,
                    onChanged: (val) => setSheetState(() => zoneType = val!),
                  ),
                  const Text("Restricted", style: TextStyle(fontSize: 14)),
                ],
              ),
              if (zoneType == 'risk') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: maxTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Max Time (Minutes)",
                    hintText: "e.g., 30",
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                "Severity Level",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['low', 'medium', 'high', 'extreme'].map((s) {
                  bool isSelected = severity == s;
                  return GestureDetector(
                    onTap: () => setSheetState(() => severity = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getSeverityColor(s)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getSeverityColor(s)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        s.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await _riskZoneService.addRiskZone(
                      name: nameController.text.trim(),
                      latitude: _pickedPoint!.latitude,
                      longitude: _pickedPoint!.longitude,
                      radius: radius,
                      severity: severity,
                      type: zoneType,
                      maxTime: zoneType == 'risk'
                          ? int.tryParse(maxTimeController.text)
                          : null,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _pickedPoint = null);
                      PremiumToast.show(
                        context,
                        title: "Zone Deployed",
                        message:
                            "The new risk zone is now live for all tourists.",
                        type: ToastType.success,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "SAVE RISK ZONE",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditZoneSheet(Map<String, dynamic> zone) {
    final nameController = TextEditingController(text: zone['name']);
    final maxTimeController = TextEditingController(text: zone['maxTime']?.toString() ?? "30");
    double radius = (zone['radius'] as num).toDouble();
    String severity = zone['severity'] ?? 'high';
    String zoneType = zone['type'] ?? 'risk'; // 'risk' or 'restricted'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 32,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Risk Zone",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Zone Name",
                  hintText: "e.g., Landslide Hill, High Water Area",
                  prefixIcon: const Icon(Icons.label_important_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Radius: ${radius.toInt()} meters",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: radius,
                min: 100,
                max: 5000,
                divisions: 49,
                activeColor: Colors.black,
                onChanged: (val) => setSheetState(() => radius = val),
              ),
              const SizedBox(height: 16),
              const Text(
                "Zone Type",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'risk',
                    groupValue: zoneType,
                    onChanged: (val) => setSheetState(() => zoneType = val!),
                  ),
                  const Text("Risk", style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Radio<String>(
                    value: 'restricted',
                    groupValue: zoneType,
                    onChanged: (val) => setSheetState(() => zoneType = val!),
                  ),
                  const Text("Restricted", style: TextStyle(fontSize: 14)),
                ],
              ),
              if (zoneType == 'risk') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: maxTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Max Time (Minutes)",
                    hintText: "e.g., 30",
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                "Severity Level",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['low', 'medium', 'high', 'extreme'].map((s) {
                  bool isSelected = severity == s;
                  return GestureDetector(
                    onTap: () => setSheetState(() => severity = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getSeverityColor(s)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getSeverityColor(s)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        s.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await _riskZoneService.updateRiskZone(
                      zone['id'],
                      name: nameController.text.trim(),
                      radius: radius,
                      severity: severity,
                      type: zoneType,
                      maxTime: zoneType == 'risk'
                          ? int.tryParse(maxTimeController.text)
                          : null,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      PremiumToast.show(
                        context,
                        title: "Zone Updated",
                        message: "The risk zone has been successfully updated.",
                        type: ToastType.success,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "UPDATE RISK ZONE",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Risk Zone Plotter",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map Display
          Expanded(
            flex: 4,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _riskZoneService.riskZonesStream,
              builder: (context, snapshot) {
                final zones = snapshot.data ?? [];
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(13.0827, 80.2707),
                    initialZoom: 13.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.geotour.app',
                    ),
                    CircleLayer(
                      circles: zones.map((z) => CircleMarker(
                        point: LatLng(z['latitude'], z['longitude']),
                        radius: (z['radius'] as num).toDouble(),
                        useRadiusInMeter: true,
                        color: _getSeverityColor(z['severity']).withValues(alpha: 0.3),
                        borderColor: _getSeverityColor(z['severity']),
                        borderStrokeWidth: 2,
                      )).toList(),
                    ),
                    MarkerLayer(
                      markers: [
                        if (_pickedPoint != null)
                          Marker(
                            point: _pickedPoint!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 45,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // List Display
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _riskZoneService.riskZonesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final zones = snapshot.data ?? [];
                  if (zones.isEmpty) {
                    return const Center(
                      child: Text(
                        "No active risk zones plotted.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          "ACTIVE ZONES",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: zones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final z = zones[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(z['severity']).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: _getSeverityColor(z['severity']),
                                  ),
                                ),
                                title: Text(
                                  z['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  "${z['radius'].toInt()}m • ${z['severity']} • ${z['type'] ?? 'risk'}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _showEditZoneSheet(z),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_sweep_outlined,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _riskZoneService.deleteRiskZone(z['id']),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _mapController.move(
                                    LatLng(z['latitude'], z['longitude']),
                                    14.0,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddZoneSheet,
        label: const Text(
          "DEPLOY ZONE",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        icon: const Icon(Icons.add_location_alt_rounded),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}
