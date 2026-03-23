import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TripModel>>(
              stream: TripService().activeAndUpcomingTripsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trips = snapshot.data ?? [];
                if (trips.isEmpty) {
                  return const Center(
                    child: Text("No upcoming trips.\nAdd one from the home screen!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(context, trip);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    bool isActive = trip.status == TripStatus.active;
    bool isUpcoming = trip.status == TripStatus.notStarted;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                _buildStatusBadge(trip.status),
              ],
            ),
            const SizedBox(height: 12),
            // Route Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8), // Clean off-white/blue
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteNode(trip.startLocation, Icons.circle, Colors.blue),
                  if (trip.stops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 2, height: 10, color: Colors.blue.shade200),
                          Text("${trip.stops.length} intermediate stops", 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          Container(width: 2, height: 10, color: Colors.blue.shade200),
                        ],
                      ),
                    ),
                  _buildRouteNode(trip.endLocation, Icons.location_on, Colors.red),
                ],
              ),
            ),
            if (trip.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  trip.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isActive)
                  _buildButton("End trip", () {
                    TripService().endTrip(trip.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Trip completed! Moved to history.")),
                    );
                  }),
                if (isUpcoming && !TripService().hasActiveTrip)
                  _buildButton("Start trip", () => TripService().startTrip(trip.id)),
                if (isUpcoming && TripService().hasActiveTrip)
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TripStatus status) {
    String text;
    Color color;
    Color textColor;
    switch (status) {
      case TripStatus.active:
        text = "ACTIVE";
        color = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case TripStatus.notStarted:
        text = "UPCOMING";
        color = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case TripStatus.completed:
        text = "COMPLETED";
        color = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRouteNode(String location, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}