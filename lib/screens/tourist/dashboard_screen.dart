import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/trip_model.dart';
import '../../services/geo_service.dart';
import '../../services/trip_service.dart';
import '../../services/alert_service.dart';
import 'alerts_screen.dart';
import 'trips_screen.dart';
import 'maps_screen.dart';
import 'emergency_response_screen.dart';
import 'location_picker_screen.dart';
import 'trip_history_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/premium_toast.dart';
import '../../widgets/premium_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_drawer.dart';
import '../../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    AlertService().initialize();
  }

  void _onNavigate(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 1) {
      NotificationService().clearBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onNavigateToAlerts: () => _onNavigate(1)),
      const AlertsScreen(),
      const MapsScreen(),
      const TripsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true, // Allow content to scroll behind the glossy nav
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FA), // Cleaner off-white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          selectedIndex == 0
              ? "GeoTour"
              : selectedIndex == 1
              ? "Alerts"
              : selectedIndex == 2
              ? "Maps"
              : "Trips",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          if (selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripHistoryScreen(),
                  ),
                );
              },
            ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyResponseScreen(),
                ),
              );
            },
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
      body: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[selectedIndex],
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.2,
                  ), // More transparent glossy effect
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
                child: Row(
                  children: [
                    Expanded(child: navItem("Home", 0)),
                    Expanded(child: navItem("Alerts", 1)),
                    Expanded(child: navItem("Maps", 2)),
                    Expanded(child: navItem("Trips", 3)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(String title, int index) {
    bool selected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuart,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.transparent, // Subtle glossy highlight
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black, // Dark text like in the image
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToAlerts;
  const HomePage({super.key, required this.onNavigateToAlerts});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  DateTime? startDate;
  DateTime? endDate;
  final MapController _mapController = MapController();

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];

  LatLng? _startPoint;
  LatLng? _endPoint;
  final List<LatLng?> _stopPoints = [];

  bool _isAddingTrip = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GeoService().removeListener(_updateMapCenter);
    _startController.dispose();
    _endController.dispose();
    _descController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GeoService().addListener(_updateMapCenter);
    GeoService().onRiskZoneEntered = (zone) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Risk Zone Detected",
          message: "⚠️ $zone! Auto-SOS triggered.",
          type: ToastType.error,
        );
      }
    };
    _handleStartMonitoring(isInitial: true).then((_) {
       _centerMapOnUser();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check when app is resumed from background
      _handleStartMonitoring(isInitial: false);
    }
  }

  Future<void> _handleStartMonitoring({bool isInitial = false}) async {
    final status = await GeoService().startMonitoring();
    if (status != LocationStatus.enabled &&
        (!isInitial || status != LocationStatus.permissionDenied)) {
      // Don't show annoying popup on first open if it's just 'denied' (system will ask)
      // But show it if they click refresh or if it's disabled/deniedForever
      if (mounted) _handlePermissionResult(status);
    }
  }

  void _handlePermissionResult(LocationStatus status) {
    if (status == LocationStatus.enabled) return;

    String title = "Location Error";
    String message = "";
    VoidCallback? onAction;

    switch (status) {
      case LocationStatus.serviceDisabled:
        title = "GPS Disabled";
        message = "Please enable location services for travel safety tracking.";
        onAction = () => GeoService().openLocationSettings();
        break;
      case LocationStatus.permissionDenied:
        message = "Location permission is required to find your way.";
        onAction = () => _handleStartMonitoring();
        break;
      case LocationStatus.permissionDeniedForever:
        title = "Permission Blocked";
        message =
            "Location permission is blocked. Please enable in app settings.";
        onAction = () => GeoService().openAppSettings();
        break;
      default:
        break;
    }

    PremiumToast.show(
      context,
      title: title,
      message: message,
      type: ToastType.warning,
    );

    if (status != LocationStatus.enabled &&
        status != LocationStatus.permissionDenied) {
      _showPremiumSettingsDialog(title, message, onAction, status);
    }
  }

  void _showPremiumSettingsDialog(
    String title,
    String message,
    VoidCallback? onAction,
    LocationStatus status,
  ) {
    PremiumDialog.show(
      context,
      title: title,
      message: message,
      primaryLabel: "SETTINGS",
      onPrimary: onAction ?? () {},
      icon: status == LocationStatus.serviceDisabled
          ? Icons.location_off_rounded
          : Icons.security_rounded,
      accentColor: status == LocationStatus.serviceDisabled
          ? Colors.orange
          : Colors.red,
    );
  }

  // Syncs background points, doesn't force camera movements
  void _updateMapCenter() {
    final pos = GeoService().currentPosition;
    if (pos != null && mounted) {
      if (_startController.text == "Current Location") {
        setState(() {
          _startPoint = LatLng(pos.latitude, pos.longitude);
        });
      }
    }
  }

  // Force jumps the camera to the user explicitly
  void _centerMapOnUser() {
    final pos = GeoService().currentPosition;
    if (pos != null && mounted) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Select Date";
    return "${date.day}/${date.month}/${date.year}";
  }

  int duration() {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  Future<DateTime?> openCalendar() async {
    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay;

    return await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xffeeeeee),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return TableCalendar(
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    focusedDay: focusedDay,
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                    selectedDayPredicate: (day) {
                      return isSameDay(selectedDay, day);
                    },
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                      Navigator.pop(context, selected);
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GeoService(),
      builder: (context, _) {
        final currentPos = GeoService().currentPosition;
        final mapCenter = currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : const LatLng(13.0827, 80.2707);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none, // Allow content to flow into padded areas
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                /// WELCOME
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tourists')
                      .doc(AuthService().currentUser?.uid ?? "")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }

                    String name = "";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      name = data['username'] ?? data['name'] ?? "";
                    }

                    if (name.isEmpty) {
                      name =
                          (AuthService().currentUser?.displayName ?? "Tourist")
                              .split(' ')
                              .first;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        StreamBuilder<List<TripModel>>(
                          stream: TripService().activeAndUpcomingTripsStream,
                          builder: (context, snapshot) {
                            bool isActive =
                                snapshot.hasData &&
                                snapshot.data!.any(
                                  (t) => t.status == TripStatus.active,
                                );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? "Active Trip" : "Idle",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                /// LOCATION CARD (MAP CONTAINER)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFFAFAFA)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFF1F1F1),
                      width: 1.5,
                    ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Your location",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Text(
                                "Testing Mode",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: GeoService().isManualOverride ? Colors.redAccent : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.65,
                                child: Switch(
                                  value: GeoService().isManualOverride,
                                  activeColor: Colors.redAccent,
                                  onChanged: (value) {
                                    if (value) {
                                      GeoService().setManualOverrideStatus(true);
                                      PremiumToast.show(
                                        context,
                                        title: "Spoofing Enabled",
                                        message: "Hardware GPS disabled. Tap 'Explore Map' to drop testing pins.",
                                        type: ToastType.info,
                                      );
                                    } else {
                                      GeoService().setManualOverrideStatus(false);
                                      _handleStartMonitoring();
                                      _centerMapOnUser();
                                      PremiumToast.show(
                                        context,
                                        title: "Live Tracking Resumed",
                                        message: "Hardware GPS tracking enabled.",
                                        type: ToastType.success,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  GeoService().resetManualOverride();
                                  _handleStartMonitoring();
                                  _centerMapOnUser();
                                  if (mounted) {
                                    PremiumToast.show(
                                      context,
                                      title: "Location Refreshed",
                                      message: "Re-scanning current GPS coordinates...",
                                      type: ToastType.success,
                                    );
                                  }
                                },
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  size: 20,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.radar_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Safe Range: ${GeoService().warningRange.toInt()}m",
                            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Slider(
                              value: GeoService().warningRange,
                              min: 100,
                              max: 2000,
                              divisions: 19,
                              activeColor: Colors.blueAccent.withValues(alpha: 0.5),
                              onChanged: (val) {
                                GeoService().setWarningRange(val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationPickerScreen(
                                title: "Explore Map",
                              ),
                            ),
                          );
                          if (result != null) {
                            final point = result['point'] as LatLng;
                            GeoService().overridePosition(point);
                            _centerMapOnUser();
                            if (mounted) {
                              PremiumToast.show(
                                context,
                                title: "Location Spoofed",
                                message: "Simulating GPS at ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}. Checking active zones...",
                                type: ToastType.info,
                              );
                            }
                          }
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: mapCenter,
                                    initialZoom: 13.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.geotour.app',
                                    ),
                                    CircleLayer(
                                      circles: GeoService().riskZones.map((z) => CircleMarker(
                                        point: z["center"] as LatLng,
                                        radius: (z["radius"] as num).toDouble(),
                                        useRadiusInMeter: true,
                                        color: Colors.red.withValues(alpha: 0.3),
                                        borderColor: Colors.red,
                                        borderStrokeWidth: 2,
                                      )).toList(),
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: mapCenter,
                                          width: 80,
                                          height: 80,
                                          child: const Icon(
                                            Icons.location_on,
                                            color: Colors.blue,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        GeoService().isManualOverride
                            ? "Manual Location Selected (Spoofed)"
                            : currentPos != null
                                ? "Last location update: Just now"
                                : "Waiting for GPS...",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: GeoService().isManualOverride ? FontWeight.bold : FontWeight.normal,
                          color: GeoService().isManualOverride ? Colors.redAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ADD TRIP CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFFAFAFA)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFF1F1F1),
                      width: 1.5,
                    ),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Plan New Trip",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Trip Route",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Start Location
                      _buildTripInputField(
                        _startController,
                        "Start Location",
                        Icons.circle_outlined,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationPickerScreen(
                                title: "Select Start Location",
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _startController.text = result['name'];
                              _startPoint = result['point'];
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Intermediate Stops
                      ..._stopControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTripInputField(
                                  entry.value,
                                  "Stop ${idx + 1}",
                                  Icons.more_vert,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocationPickerScreen(
                                              title: "Select Stop ${idx + 1}",
                                            ),
                                      ),
                                    );
                                    if (result != null) {
                                      setState(() {
                                        _stopControllers[idx].text =
                                            result['name'];
                                        if (idx < _stopPoints.length) {
                                          _stopPoints[idx] = result['point'];
                                        } else {
                                          _stopPoints.add(result['point']);
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => setState(() {
                                  _stopControllers[idx].dispose();
                                  _stopControllers.removeAt(idx);
                                  if (idx < _stopPoints.length) {
                                    _stopPoints.removeAt(idx);
                                  }
                                }),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Add Stop Button
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _stopControllers.add(TextEditingController());
                          _stopPoints.add(null);
                        }),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          "Add Stop",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      // End Location
                      _buildTripInputField(
                        _endController,
                        "End Location",
                        Icons.location_on,
                        color: Colors.red,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationPickerScreen(
                                title: "Select End Location",
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _endController.text = result['name'];
                              _endPoint = result['point'];
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Trip Description",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Enter trip details...",
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Start Date",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await openCalendar();
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                            });
                          }
                        },
                        child: dateBox(formatDate(startDate)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "End Date",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await openCalendar();
                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                        child: dateBox(formatDate(endDate)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Duration: ${duration()} Days",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (_isAddingTrip) return;
                              
                              if (startDate != null &&
                                  endDate != null &&
                                  _startController.text.isNotEmpty &&
                                  _endController.text.isNotEmpty) {
                                  
                                setState(() => _isAddingTrip = true);
                                
                                final uid = AuthService().currentUser?.uid ?? '';

                                PremiumToast.show(
                                  context,
                                  title: "Planning Trip",
                                  message: "Adding your new journey to GeoTour...",
                                  type: ToastType.info,
                                );

                                try {
                                  await TripService().addTrip(
                                    TripModel(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      userId: uid,
                                      title: "${duration()} Days Trip",
                                      description: _descController.text,
                                      startLocation: _startController.text,
                                      startPoint: _startPoint,
                                      endLocation: _endController.text,
                                      endPoint: _endPoint,
                                      stops: _stopControllers.map((c) => c.text).toList(),
                                      stopPoints: _stopPoints.whereType<LatLng>().toList(),
                                      startDate: startDate!,
                                      endDate: endDate!,
                                      status: TripStatus.notStarted,
                                    ),
                                  );

                                  // Clear inputs
                                  _startController.clear();
                                  _endController.clear();
                                  _descController.clear();
                                  for (var c in _stopControllers) {
                                    c.dispose();
                                  }
                                  setState(() {
                                    _stopControllers.clear();
                                    _startPoint = null;
                                    _endPoint = null;
                                    _stopPoints.clear();
                                    startDate = null;
                                    endDate = null;
                                  });

                                  if (mounted) {
                                    PremiumToast.show(
                                      context,
                                      title: "Trip Added",
                                      message: "Your new trip has been successfully planned!",
                                      type: ToastType.success,
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isAddingTrip = false);
                                }
                              } else {
                                PremiumToast.show(
                                  context,
                                  title: "Missing Locations",
                                  message: "Please select start/end points and trial dates.",
                                  type: ToastType.warning,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isAddingTrip 
                                  ? const SizedBox(
                                      height: 16, 
                                      width: 16, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : const Text(
                                      "Add",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ALERTS AND RISKS CARD
                ListenableBuilder(
                  listenable: AlertService(),
                  builder: (context, _) {
                    final alerts = AlertService().alerts;

                    return GestureDetector(
                      onTap: widget.onNavigateToAlerts,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Recent Alerts and Risks",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: const [
                                    Text(
                                      "View All",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (alerts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "No recent alerts.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              ...alerts
                                  .take(4)
                                  .map(
                                    (alert) => alertCard(
                                      alert.title,
                                      alert.timeAgo,
                                      alert.color,
                                      Colors.black87,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget dateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8), // Clean off-white/blue
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: text == "Select Date"
                  ? Colors.grey.shade500
                  : Colors.black,
              fontWeight: text == "Select Date"
                  ? FontWeight.w400
                  : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Icon(
            Icons.calendar_month_rounded,
            size: 20,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget alertCard(String text, String time, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor.withValues(
          alpha: 0.1,
        ), // Cleaner semi-transparent background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.black, // High contrast text
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildTripInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, size: 22, color: color ?? Colors.blue.shade600),
        filled: true,
        fillColor: const Color(0xFFF1F4F8), // Clean filled style
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.blue.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
