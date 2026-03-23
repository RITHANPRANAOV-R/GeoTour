import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../services/geo_service.dart';

class TripDetailScreen extends StatelessWidget {
  final TripModel trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    bool isActive = trip.status == TripStatus.active;
    bool isUpcoming = trip.status == TripStatus.notStarted;

    // Collect all valid points for the route
    final List<LatLng> routePoints = [];
    if (trip.startPoint != null) routePoints.add(trip.startPoint!);
    routePoints.addAll(trip.stopPoints);
    if (trip.endPoint != null) routePoints.add(trip.endPoint!);

    return Scaffold(
      backgroundColor: const Color(0xffeeeeee),
      appBar: AppBar(
        title: const Text(
          "Trip Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: ListenableBuilder(
        listenable: GeoService(),
        builder: (context, _) {
          final currentPos = GeoService().currentPosition;
          final userLocation = currentPos != null
              ? LatLng(currentPos.latitude, currentPos.longitude)
              : null;

          final mapCenter =
              userLocation ??
              (routePoints.isNotEmpty
                  ? routePoints.first
                  : const LatLng(13.0827, 80.2707));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Preview with Route Plotting
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 13.0,
                        initialCameraFit: routePoints.length >= 2
                            ? CameraFit.bounds(
                                bounds: LatLngBounds.fromPoints(routePoints),
                                padding: const EdgeInsets.all(50),
                              )
                            : null,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.geotour.app',
                        ),
                        if (routePoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                color: Colors.blue.withValues(alpha: 0.8),
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // Waypoint Markers
                            if (trip.startPoint != null)
                              Marker(
                                point: trip.startPoint!,
                                width: 30,
                                height: 30,
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ...trip.stopPoints.map(
                              (p) => Marker(
                                point: p,
                                width: 30,
                                height: 30,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                            if (trip.endPoint != null)
                              Marker(
                                point: trip.endPoint!,
                                width: 35,
                                height: 35,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 28,
                                ),
                              ),

                            // Current Location Marker
                            if (userLocation != null)
                              Marker(
                                point: userLocation,
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFAFAFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F1F1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow(
                        Icons.calendar_today,
                        "Dates",
                        "${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year} - ${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}",
                      ),
                      _buildDetailRow(
                        Icons.timer_outlined,
                        "Duration",
                        "${trip.durationInDays} Days",
                      ),

                      const Divider(height: 32),

                      const Text(
                        "Planned Route",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildRouteItem(
                        trip.startLocation,
                        "Start",
                        Colors.blue,
                        isFirst: true,
                        point: trip.startPoint,
                      ),
                      ...List.generate(
                        trip.stops.length,
                        (i) => _buildRouteItem(
                          trip.stops[i],
                          "Stop ${i + 1}",
                          Colors.grey,
                          point: i < trip.stopPoints.length
                              ? trip.stopPoints[i]
                              : null,
                        ),
                      ),
                      _buildRouteItem(
                        trip.endLocation,
                        "End",
                        Colors.red,
                        isLast: true,
                        point: trip.endPoint,
                      ),

                      if (trip.description.isNotEmpty) ...[
                        const Divider(height: 32),
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trip.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      if (isActive)
                        _buildActionButton("End Trip", Colors.red, () {
                          TripService().endTrip(trip.id);
                          Navigator.pop(context);
                        }),
                      if (isUpcoming && !TripService().hasActiveTrip)
                        _buildActionButton("Start Trip", Colors.black, () {
                          TripService().startTrip(trip.id);
                          Navigator.pop(context);
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteItem(
    String location,
    String type,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
    LatLng? point,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                ],
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "GPS: (${point?.latitude.toStringAsFixed(4) ?? 'None'}, ${point?.longitude.toStringAsFixed(4) ?? 'None'})",
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
