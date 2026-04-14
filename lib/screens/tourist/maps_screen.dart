import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/geo_service.dart';
import 'location_picker_screen.dart';
import '../../widgets/premium_toast.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  LatLng? _destination;
  String? _destinationName;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _distance;
  String? _duration;

  @override
  void initState() {
    super.initState();
    // Don't auto-reset center if user is navigating/interacting
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    setState(() => _isLoadingRoute = true);

    // Using OSRM Public API (Free, No Key)
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final geometry = route['geometry']['coordinates'] as List;

        setState(() {
          _routePoints = geometry
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
          _distance = (route['distance'] / 1000).toStringAsFixed(1) + " km";
          _duration = (route['duration'] / 60).toStringAsFixed(0) + " min";
          _isLoadingRoute = false;
        });

        // Fit map to show both points
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([start, end]),
            padding: const EdgeInsets.all(80),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Routing Error",
          message: "Unable to calculate route. Check your connection.",
          type: ToastType.error,
        );
      }
      setState(() => _isLoadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GeoService(),
      builder: (context, _) {
        final currentPos = GeoService().currentPosition;
        final userPos = currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : const LatLng(13.0827, 80.2707);

        final riskZones = GeoService().riskZones;

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userPos,
                initialZoom: 13.0,
                onTap: (tapPos, point) {
                  setState(() {
                    _routePoints = [];
                    _destination = null;
                    _distance = null;
                    _duration = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.geotour.app',
                ),
                CircleLayer(
                  circles: riskZones
                      .map(
                        (zone) => CircleMarker(
                          point: zone["center"] as LatLng,
                          radius: (zone["radius"] as num).toDouble(),
                          useRadiusInMeter: true,
                          color: Colors.red.withValues(alpha: 0.3),
                          borderColor: Colors.red,
                          borderStrokeWidth: 2,
                        ),
                      )
                      .toList(),
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 6,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userPos,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Search Bar (Google Maps Style)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationPickerScreen(
                              title: "Search Destination",
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _destination = result['point'];
                            _destinationName = result['name'];
                          });
                          _getRoute(userPos, result['point']);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _destinationName ??
                                    "Search for a destination...",
                                style: TextStyle(
                                  color: _destinationName != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_destinationName != null)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _destination = null;
                                    _destinationName = null;
                                    _routePoints = [];
                                    _distance = null;
                                    _duration = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Info Overlay (Bottom)
            if (_distance != null)
              Positioned(
                bottom: 110, // Adjust to be above the bottom nav bar
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _duration ?? "",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  _distance ?? "",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              PremiumToast.show(
                                context,
                                title: "Simulation Active",
                                message:
                                    "Mode enabled. Stay on the highlighted path!",
                                type: ToastType.info,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.black, // Professional black button
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Start",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_isLoadingRoute)
              const Center(child: CircularProgressIndicator()),

            // FAB shifted up to avoid being behind the bar
            if (_distance == null)
              Positioned(
                bottom: 110,
                right: 16,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (currentPos != null) {
                      _mapController.move(userPos, 15.0);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),
          ],
        );
      },
    );
  }
}
