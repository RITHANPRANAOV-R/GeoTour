import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/geo_service.dart';
import '../../services/chat_service.dart';
import '../../models/alert_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/hospital_service.dart';
import '../../models/hospital_model.dart';
import '../../services/police_service.dart';
import '../../models/officer_model.dart';
import 'police_chat_screen.dart';
import '../common/call_screen.dart';
import '../../widgets/premium_toast.dart';
import '../../widgets/premium_dialog.dart';

class EmergencyResponseScreen extends StatefulWidget {
  const EmergencyResponseScreen({super.key});

  @override
  State<EmergencyResponseScreen> createState() =>
      _EmergencyResponseScreenState();
}

class _EmergencyResponseScreenState extends State<EmergencyResponseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedRisk;
  String? activeAlertId;
  bool sosTriggered = false;

  List<LatLng> _routePoints = [];
  String? _distance;
  String? _duration;
  bool _isLoadingRoute = false;
  LatLng? _lastRouteUpdatePos;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check for existing active alerts
    AlertService().addListener(_checkActiveAlerts);
    _checkActiveAlerts();
  }

  void _checkActiveAlerts() {
    final alerts = AlertService().alerts;

    // First priority: any alert that is already assigned to an officer
    final assignedAlert = alerts
        .where((a) => a.status == 'assigned')
        .firstOrNull;

    // Second priority: the latest pending alert
    final pendingAlert = alerts.where((a) => a.status == 'pending').firstOrNull;

    final activeAlert = assignedAlert ?? pendingAlert;

    if (activeAlert != null) {
      if (mounted) {
        // If we haven't triggered SOS yet, or if the active ID has changed (e.g. from pending to assigned)
        if (!sosTriggered || activeAlertId != activeAlert.id) {
          setState(() {
            sosTriggered = true;
            activeAlertId = activeAlert.id;
            if (activeAlert.status == 'assigned') {
              _tabController.animateTo(1);
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    AlertService().removeListener(_checkActiveAlerts);
    _tabController.dispose();
    super.dispose();
  }

  void _updateRouteIfNeeded(LatLng userPos, LatLng responderPos) {
    if (_lastRouteUpdatePos == null ||
        Distance().as(LengthUnit.Meter, _lastRouteUpdatePos!, responderPos) > 15) {
      _lastRouteUpdatePos = responderPos;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _getRoute(userPos, responderPos);
        }
      });
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

  void _triggerSOS(String risk) async {
    final pos = GeoService().currentPosition;
    final lat = pos?.latitude ?? 0.0;
    final lng = pos?.longitude ?? 0.0;

    AlertSeverity severity = AlertSeverity.medium;
    if (risk == "High") severity = AlertSeverity.high;
    if (risk == "Extreme") severity = AlertSeverity.extreme;

    final id = await AlertService().addAlert(
      title: "Manual SOS: $risk Risk",
      description: "User manually triggered SOS signal from Emergency screen.",
      severity: severity,
      lat: lat,
      lng: lng,
      notifyPolice: true,
    );

    if (id == null && mounted) {
      PremiumToast.show(
        context,
        title: "SOS Failed",
        message: "Failed to trigger broadcast. Check your network connection.",
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      selectedRisk = risk;
      sosTriggered = true;
      activeAlertId = id;
    });
  }

  void _sendHospitalSOS(String riskLevel) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final pos = GeoService().currentPosition;
    if (pos == null) {
      final status = await GeoService().startMonitoring();
      if (status != LocationStatus.enabled) {
        if (mounted) _handleLocationStatus(status);
        return;
      }
    }

    // Check again
    final finalPos = GeoService().currentPosition;
    if (finalPos == null) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Waiting for GPS",
          message: "Please ensure your location is enabled to dispatch help.",
          type: ToastType.warning,
        );
      }
      return;
    }

    final posData = finalPos; // use the one we just verified

    // Get actual name and medical info from the 'tourists' collection
    final touristDoc = await FirebaseFirestore.instance
        .collection('tourists')
        .doc(user.uid)
        .get();

    final touristData = touristDoc.data();
    final m = touristData?['medicalInfo'] as Map<String, dynamic>?;

    final victimName =
        touristData?['username'] ?? user.displayName ?? "Tourist";
    final medicalSummary =
        "Blood: ${m?['bloodGroup'] ?? 'N/A'}, Meds: ${m?['medications'] ?? 'None'}, Allergies: ${m?['allergies'] ?? 'None'}";

    try {
      // Find nearest hospital from the first document in the pool for now
      // A more complex implementation would sort by distance
      // Find nearest AVAILABLE hospital
      // Broadcast to ALL hospitals instead of just one
      const String nearestHospitalId = 'all';

        final ec = touristData?['emergencyContact'] as Map<String, dynamic>?;
        final contactStr = ec != null ? "${ec['name']} (${ec['phone']})" : null;

      await HospitalService().triggerHospitalSOS(
        victimId: user.uid,
        victimName: victimName,
        lat: posData.latitude,
        lng: posData.longitude,
        medicalInfo: medicalSummary,
        phone: touristData?['phone'],
        contacts: contactStr,
        hospitalId: nearestHospitalId,
        riskLevel: riskLevel,
      );

      if (mounted) {
        PremiumToast.show(
          context,
          title: "Medical Alert Dispatched",
          message: "Emergency broadcast sent to all nearby medical facilities.",
          type: ToastType.error,
        );
        setState(() => sosTriggered = true);
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "SOS Error",
          message: "Unable to dispatch medical alert: ${e.toString()}",
          type: ToastType.error,
        );
      }
    }
  }

  void _sendPoliceSOS(String riskLevel) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final pos = GeoService().currentPosition;
    if (pos == null) {
      final status = await GeoService().startMonitoring();
      if (status != LocationStatus.enabled) {
        if (mounted) _handleLocationStatus(status);
        return;
      }
    }

    // Check again after (potentially) re-enabling
    final finalPos = GeoService().currentPosition;
    if (finalPos == null) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Waiting for GPS",
          message: "Please ensure your location is enabled to dispatch help.",
          type: ToastType.warning,
        );
      }
      return;
    }

    try {
      // Fetch real medical info from the 'tourists' collection
      final touristDoc = await FirebaseFirestore.instance
          .collection('tourists')
          .doc(user.uid)
          .get();

      final touristData = touristDoc.data();
      final m = touristData?['medicalInfo'] as Map<String, dynamic>?;
      final medicalSummary =
          "Blood: ${m?['bloodGroup'] ?? 'N/A'}, Meds: ${m?['medications'] ?? 'None'}, Allergies: ${m?['allergies'] ?? 'None'}";

      // Find nearest available officer
      final officers = await PoliceService().getAvailableOfficersStream().first;
      String? nearestOfficerId;
      if (officers.isNotEmpty) {
        nearestOfficerId = officers.first.uid;
      }

      final ec = touristData?['emergencyContact'] as Map<String, dynamic>?;
      final contactStr = ec != null ? "${ec['name']} (${ec['phone']})" : null;

      await PoliceService().triggerPoliceSOS(
        victimId: user.uid,
        victimName: touristData?['username'] ?? user.displayName ?? "Tourist",
        lat: finalPos.latitude,
        lng: finalPos.longitude,
        threat: "Emergency SOS: $riskLevel Risk",
        riskLevel: riskLevel,
        medicalInfo: medicalSummary,
        phone: touristData?['phone'],
        contacts: contactStr,
        officerId: nearestOfficerId,
        touristId: touristData?['touristId'],
      );

      if (mounted) {
        PremiumToast.show(
          context,
          title: "Police Alert Dispatched",
          message: nearestOfficerId != null
              ? "Emergency request sent to the nearest patrol unit."
              : "Emergency request broadcasted to all active units.",
          type: ToastType.error,
        );
        setState(() => sosTriggered = true);
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "SOS Error",
          message: "Unable to contact police network: $e",
          type: ToastType.error,
        );
      }
    }
  }

  void _showRiskDialog(Function(String) onSelected) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Risk Level",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please assess the current threat level",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...["Low", "Medium", "High", "Extreme"].map((risk) {
                      Color riskColor;
                      switch (risk) {
                        case "Low":
                          riskColor = Colors.green;
                          break;
                        case "Medium":
                          riskColor = Colors.orange;
                          break;
                        case "High":
                          riskColor = Colors.red;
                          break;
                        case "Extreme":
                          riskColor = Colors.red.shade900;
                          break;
                        default:
                          riskColor = Colors.blue;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onSelected(risk);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: riskColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                risk,
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
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
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Emergency Response",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () => _showRiskDialog((risk) => _triggerSOS(risk)),
                child: Container(
                  margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "SOS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMedicalTab(),
              _buildPoliceTab(),
              _buildOthersTab(),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    indicatorPadding: const EdgeInsets.all(6),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      const Tab(text: "Medical"),
                      const Tab(text: "Police"),
                      StreamBuilder<QuerySnapshot>(
                        stream: ChatService().getConversationsStream(
                          AuthService().currentUser?.uid ?? "",
                        ),
                        builder: (context, snapshot) {
                          int unreadCount = 0;
                          if (snapshot.hasData) {
                            final uid = AuthService().currentUser?.uid;
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final counts = data['unreadCounts'] as Map<String, dynamic>?;
                              if (uid != null && counts != null) {
                                unreadCount += (counts[uid] ?? 0) as int;
                              }
                            }
                          }

                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Others"),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      unreadCount > 9 ? "9+" : "$unreadCount",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton:
              (_tabController.index == 0 || _tabController.index == 1)
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: FloatingActionButton(
                    onPressed: () {
                      _showRiskDialog((risk) {
                        if (_tabController.index == 0) {
                          _sendHospitalSOS(risk);
                        } else {
                          _sendPoliceSOS(risk);
                        }
                      });
                    },
                    shape: const CircleBorder(),
                    backgroundColor: Colors.black,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMedicalTab() {
    final user = AuthService().currentUser;
    return StreamBuilder<List<HospitalModel>>(
      stream: HospitalService().getNearestHospitalsStream(),
      builder: (context, snapshot) {
        final alert = AlertService().alerts
            .where((a) => a.status != 'completed')
            .firstOrNull;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMapCard(),
              const SizedBox(height: 20),
              if (alert != null) ...[
                const Text(
                  "Response Tracking",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Medical Team Dispatched",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Status: ${alert.status.toUpperCase()}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                "Nearest Hospital",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                const Text(
                  "No nearby hospitals found.",
                  style: TextStyle(color: Colors.grey),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      ...snapshot.data!.take(3).map((hospital) {
                        return Column(
                          children: [
                            _hospitalItem(
                              hospital.name,
                              hospital.distance > 0
                                  ? "${hospital.distance.toStringAsFixed(1)} km"
                                  : "Nearby",
                              hospital.latitude,
                              hospital.longitude,
                            ),
                            const Divider(),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                "Medical Info",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tourists')
                    .doc(user?.uid ?? "")
                    .snapshots(),
                builder: (context, snapshot) {
                  Map<String, dynamic> info = {
                    "Blood Group": "N/A",
                    "Current Medications": "None",
                    "Allergies": "None",
                    "Surgeries": "None",
                  };

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    if (data.containsKey('medicalInfo')) {
                      final m = data['medicalInfo'] as Map<String, dynamic>;
                      info["Blood Group"] = m['bloodGroup'] ?? "N/A";
                      info["Current Medications"] = m['medications'] ?? "None";
                      info["Allergies"] = m['allergies'] ?? "None";
                      info["Surgeries"] = m['surgeries'] ?? "None";
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: info.entries
                          .map((e) => _infoItem(e.key, e.value))
                          .toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoliceTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: activeAlertId != null
          ? FirebaseFirestore.instance
                .collection('alerts')
                .doc(activeAlertId)
                .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final status = data?['status'] ?? 'pending';
        final officerName = data?['acceptedByName'];
        final bool isCompleted = status == 'completed';
        final bool isAssigned =
            !isCompleted &&
            (activeAlertId != null && data != null) &&
            (status == 'assigned' || officerName != null);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAssigned) ...[
                _buildMapCard(),
                const SizedBox(height: 20),
                StreamBuilder<List<OfficerModel>>(
                  stream: PoliceService().getAvailableOfficersStream(),
                  builder: (context, officerSnapshot) {
                    if (officerSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !officerSnapshot.hasData) {
                      return const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Colors.blue),
                            SizedBox(height: 16),
                            Text(
                              "Finding nearby available officers...",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }

                    final officers = officerSnapshot.data ?? [];
                    if (officers.isEmpty) {
                      return const Center(
                        child: Text(
                          "No officers currently available nearby",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: officers.length,
                        itemBuilder: (context, index) {
                          final off = officers[index];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue.shade50,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  off.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Badge ${off.badgeNumber}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ] else ...[
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('police')
                      .doc(data['acceptedBy'])
                      .snapshots(),
                  builder: (context, offSnap) {
                    LatLng? responderPos;
                    String? resolvedName = officerName;

                    if (offSnap.hasData && offSnap.data!.exists) {
                      final offData =
                          offSnap.data!.data() as Map<String, dynamic>;
                      final geo = offData['location'] as GeoPoint?;
                      if (geo != null) {
                        responderPos = LatLng(geo.latitude, geo.longitude);
                      }
                      // Use the real-time name from the profile if available
                      resolvedName = offData['name'] ?? officerName;
                    }

                    // Avoid "Officer Officer" or "Officer null"
                    final displayName = resolvedName ?? "Officer";
                    final displayLabel = displayName.toLowerCase().contains("officer") 
                        ? displayName 
                        : "Officer $displayName";

                    return Column(
                      children: [
                        _buildMapCard(responderPos: responderPos),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Estimated Arrival",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Active Pursuit",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "$displayLabel is en-route tracking your live location",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        _buildResponderCard(
                          displayName,
                          data['acceptedBy'] ?? "#0000",
                          chatId: activeAlertId!,
                          recipientId: data['acceptedBy'],
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOthersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in"));

    return StreamBuilder<QuerySnapshot>(
      stream: ChatService().getConversationsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Error loading chats: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No active conversations",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!.docs.toList();
        
        // Manual sort by timestamp (newest first) to avoid index requirement
        conversations.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['lastTimestamp'] as Timestamp?;
          final bTime = bData['lastTimestamp'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final chat = conversations[index].data() as Map<String, dynamic>;
            final chatId = conversations[index].id;
            final participants = List<String>.from(chat['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != user.uid,
              orElse: () => "",
            );

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('police')
                  .doc(otherUserId)
                  .get(),
              builder: (context, offSnap) {
                String name = "Officer";
                String? image;
                if (offSnap.hasData && offSnap.data!.exists) {
                  final offData = offSnap.data!.data() as Map<String, dynamic>;
                  name = offData['name'] ?? "Officer";
                  image = offData['profileImage'];
                } else {
                  // Fallback: If not found in police collection, use the name from the alert document
                  name = chat['acceptedByName'] ?? "Responder";
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: image != null
                          ? NetworkImage(image)
                          : null,
                      child: image == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chat['lastMessage'] ?? "No messages yet",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (chat['unreadCounts'] != null &&
                            chat['unreadCounts'][user.uid] != null &&
                            chat['unreadCounts'][user.uid] > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${chat['unreadCounts'][user.uid]}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PoliceChatScreen(
                            chatId: chatId,
                            recipientId: otherUserId,
                            recipientName: name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMapCard({LatLng? responderPos}) {
    return ListenableBuilder(
      listenable: GeoService(),
      builder: (context, _) {
        final pos = GeoService().currentPosition;
        final userLatLng = pos != null
            ? LatLng(pos.latitude, pos.longitude)
            : null;

        if (userLatLng != null && responderPos != null) {
          _updateRouteIfNeeded(userLatLng, responderPos);
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Live Status",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        responderPos != null
                            ? "Tracking responder..."
                            : "Broadcasting location...",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (_distance != null && _duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$_distance • $_duration",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "GPS LIVE",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          userLatLng ?? const LatLng(13.0827, 80.2707),
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.geotour.app',
                      ),
                      MarkerLayer(
                        markers: [
                          if (userLatLng != null)
                            Marker(
                              point: userLatLng,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.location_history_rounded,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          if (responderPos != null)
                            Marker(
                              point: responderPos,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.local_police_rounded,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
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
                        )
                      else if (userLatLng != null && responderPos != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [userLatLng, responderPos],
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                              strokeWidth: 4,
                              pattern: const StrokePattern.dotted(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        PremiumToast.show(
          context,
          title: "Launch Error",
          message: "Error launching maps: $e",
          type: ToastType.error,
        );
      }
    }
  }

  Widget _hospitalItem(String name, String dist, double lat, double lng) {
    return InkWell(
      onTap: () => _openInMaps(lat, lng),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dist,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.directions_rounded, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildResponderCard(
    String name,
    String badge, {
    required String chatId,
    required String recipientId,
    String? imageUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Assigned Responder",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl ?? "https://via.placeholder.com/80",
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toLowerCase().contains("officer") ? name : "Officer $name",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      "Badge #$badge",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  Icons.call,
                  "Call",
                  Colors.black,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          name: name,
                          role: "Police Officer",
                          image: imageUrl,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  Icons.chat,
                  "Chat",
                  Colors.black,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PoliceChatScreen(
                          chatId: chatId,
                          recipientId: recipientId,
                          recipientName: name,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLocationStatus(LocationStatus status) {
    String title = "Location Error";
    String message = "";
    VoidCallback? onAction;

    switch (status) {
      case LocationStatus.serviceDisabled:
        title = "GPS is OFF";
        message = "Safety features require GPS. Turn it on now?";
        onAction = () => GeoService().openLocationSettings();
        break;
      case LocationStatus.permissionDenied:
        message = "Permission is needed to find your location.";
        onAction = () => GeoService().startMonitoring();
        break;
      case LocationStatus.permissionDeniedForever:
        title = "Permission Blocked";
        message = "Location is blocked. Please fix in settings.";
        onAction = () => GeoService().openAppSettings();
        break;
      default:
        return;
    }

    PremiumDialog.show(
      context,
      title: title,
      message: message,
      primaryLabel: "FIX NOW",
      onPrimary: onAction,
      icon: status == LocationStatus.serviceDisabled
          ? Icons.location_disabled_rounded
          : Icons.gpp_maybe_rounded,
      accentColor: status == LocationStatus.serviceDisabled
          ? Colors.orange
          : Colors.red,
    );
  }
}
