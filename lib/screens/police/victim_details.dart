import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/police_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/geo_service.dart';
import '../tourist/police_chat_screen.dart';
import '../common/call_screen.dart';

class VictimDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> victimData;

  const VictimDetailsScreen({super.key, required this.victimData});

  @override
  State<VictimDetailsScreen> createState() => _VictimDetailsScreenState();
}

class _VictimDetailsScreenState extends State<VictimDetailsScreen> {
  final MapController _mapController = MapController();
  final PoliceService _policeService = PoliceService();
  bool _isFirstLoad = true;
  List<LatLng> _routePoints = [];
  String? _distance;
  String? _duration;
  bool _isLoadingRoute = false;
  LatLng? _lastPolicePos;

  @override
  void initState() {
    super.initState();
    GeoService().startMonitoring();
    GeoService().addListener(_handleLocationUpdate);
  }

  @override
  void dispose() {
    GeoService().removeListener(_handleLocationUpdate);
    super.dispose();
  }

  void _handleLocationUpdate() {
    final pos = GeoService().currentPosition;
    if (pos != null) {
      final newPos = LatLng(pos.latitude, pos.longitude);
      if (_lastPolicePos == null ||
          Distance().as(LengthUnit.Meter, _lastPolicePos!, newPos) > 10) {
        _lastPolicePos = newPos;
        _updateRouteIfNeeded();
      }
    }
  }

  LatLng? _currentVictimPos;

  void _updateRouteIfNeeded() {
    if (_lastPolicePos != null && _currentVictimPos != null) {
      _getRoute(_lastPolicePos!, _currentVictimPos!);
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    if (_isLoadingRoute) return;
    setState(() => _isLoadingRoute = true);

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;

          if (mounted) {
            setState(() {
              _routePoints = geometry
                  .map((coord) => LatLng(coord[1], coord[0]))
                  .toList();
              _distance = (route['distance'] / 1000).toStringAsFixed(1) + " km";
              _duration = (route['duration'] / 60).toStringAsFixed(0) + " min";
              _isLoadingRoute = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");
    final Uri universalUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          await launchUrl(universalUrl, mode: LaunchMode.externalApplication);
        }
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl);
        } else {
          await launchUrl(universalUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(universalUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error launching maps: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String alertId = widget.victimData['id'] ?? '';
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: _policeService.getAlertStream(alertId),
      builder: (context, snapshot) {
        Map<String, dynamic> data = widget.victimData;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          data['id'] = alertId;
        }

        final GeoPoint? geoPoint = data['location'] as GeoPoint?;
        final LatLng? victimPos = geoPoint != null
            ? LatLng(geoPoint.latitude, geoPoint.longitude)
            : null;

        if (victimPos != null && _currentVictimPos != victimPos) {
          _currentVictimPos = victimPos;
          _updateRouteIfNeeded();
        }

        if (_isFirstLoad && victimPos != null) {
          _isFirstLoad = false;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _mapController.move(victimPos, 15.0);
          });
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Victim Details",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    "Extreme Risk",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: victimPos ?? const LatLng(0, 0),
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.geotour',
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  color: Colors.blueAccent,
                                  strokeWidth: 5,
                                ),
                              ],
                            ),
                          if (victimPos != null || _lastPolicePos != null)
                            MarkerLayer(
                              markers: [
                                if (victimPos != null)
                                  Marker(
                                    point: victimPos,
                                    width: 60,
                                    height: 60,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 
                                              0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Victim",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_lastPolicePos != null)
                                  Marker(
                                    point: _lastPolicePos!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      if (_distance != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$_distance • $_duration",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (victimPos != null)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: ElevatedButton(
                            onPressed: () => _openInMaps(
                              victimPos.latitude,
                              victimPos.longitude,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.black45,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              "Navigate",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(data),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActions(data, user),
        );
      },
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> data, User? user) {
    final String acceptedBy = data['acceptedBy'] ?? '';
    final String acceptedByName = data['acceptedByName'] ?? '';
    final String alertId = data['id'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), // True transparency
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (acceptedBy.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAcceptAlert(alertId, user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF), // Apple Blue
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 56),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              "Accept Mission",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showAssignBottomSheet(alertId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F2F7), // Apple Gray
                              foregroundColor: Colors.black,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 56),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              "Assign",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (acceptedBy == user?.uid)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PoliceChatScreen(
                                    chatId: alertId,
                                    recipientId: data['userId'] ?? "",
                                    recipientName: data['name'] ?? "Victim",
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                            label: const Text(
                              "Chat",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEBEEF2),
                              foregroundColor: const Color(0xFF007AFF),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 56),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CallScreen(
                                    name: data['name'] ?? "Victim",
                                    role: "Tourist",
                                    image: data['image'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.call_rounded, size: 20),
                            label: const Text(
                              "Call",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              foregroundColor: const Color(0xFF34C759), // iOS Green
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 56),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34C759).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => _handleCompleteMission(alertId, user!, data),
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: Center(
                        child: Text(
                          "ASSIGNED TO ${acceptedByName.toUpperCase()}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAcceptAlert(String alertId, User? user) async {
    if (user == null) return;
    final officerDoc = await _policeService.getOfficerProfile(user.uid);
    final officerName =
        (officerDoc.data() as Map<String, dynamic>?)?['name'] ?? "Officer";

    bool success = await _policeService.acceptAlert(
      alertId: alertId,
      officerId: user.uid,
      officerName: officerName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alert accepted! Mission started.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not accept alert.")),
        );
      }
    }
  }

  Future<void> _handleCompleteMission(
    String alertId,
    User user,
    Map<String, dynamic> data,
  ) async {
    await _policeService.completeMission(
      alertId: alertId,
      officerId: user.uid,
      alertData: Map<String, dynamic>.from(data),
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Mission completed.")));
      Navigator.pop(context);
    }
  }

  void _showAssignBottomSheet(String alertId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Text(
                "Assign to Officer",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _policeService.getOfficersStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final officers = snapshot.data!.docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return d['isAvailable'] == true &&
                        doc.id != FirebaseAuth.instance.currentUser?.uid;
                  }).toList();

                  if (officers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No available officers found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: officers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final officer = officers[index].data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F1F1)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            officer['name'] ?? "Unknown",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          subtitle: Text(
                            officer['badgeNumber'] != null ? "Badge: ${officer['badgeNumber']}" : "Officer",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Assigning alert..."),
                                ),
                              );

                              final success = await _policeService.assignAlert(
                                alertId: alertId,
                                officerId: officers[index].id,
                                officerName: officer['name'] ?? "Officer",
                              );

                              if (mounted) {
                                nav.pop(); // Close bottom sheet
                                if (success) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Alert assigned successfully!",
                                      ),
                                    ),
                                  );
                                  nav.pop(); // Close details screen
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Could not assign alert. It might have been accepted already.",
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text("Error: ${e.toString()}"),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> data) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.person_outline,
              "Victim",
              data['name'] ?? "Unknown",
            ),
            const Divider(height: 32, thickness: 0.5),
            _buildInfoRow(
              Icons.warning_amber_rounded,
              "Threat",
              data['threat'] ?? "Risk Zone Entry",
            ),
            const Divider(height: 32, thickness: 0.5),
            _buildInfoRow(
              Icons.phone_outlined,
              "Phone",
              data['phone'] ?? "N/A",
            ),
            const Divider(height: 32, thickness: 0.5),
            _buildInfoRow(
              Icons.contact_phone_outlined,
              "ER Contacts",
              data['contacts'] ?? "N/A",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
