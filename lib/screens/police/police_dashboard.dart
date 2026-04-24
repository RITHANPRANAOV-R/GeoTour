import 'dart:ui';
import 'package:flutter/material.dart';
import 'police_home.dart';
import 'assign_officers.dart';
import 'incidents.dart';
import 'victim_details.dart';
import '../../widgets/app_drawer.dart';
import '../../services/notification_service.dart';
import '../../services/geo_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  int _selectedIndex = 0;
  StreamSubscription? _alertSub;

  final List<Widget> _screens = [
    const PoliceHomeScreen(),
    const AssignOfficersScreen(),
    const IncidentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupAlertMonitoring();
  }

  void _setupAlertMonitoring() {
    // 1. Handle notification taps
    NotificationService().onNotificationTap = (payload) {
      if (payload != null) {
        // Find which alert matches this ID and navigate
        _navigateToAlert(payload);
      }
    };

    // 2. Listen for new pending alerts
    final startTime = DateTime.now();
    _alertSub = FirebaseFirestore.instance
        .collection('alerts')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          
          if (timestamp != null && timestamp.toDate().isAfter(startTime)) {
            NotificationService().showNotification(
              id: change.doc.id.hashCode,
              title: "🚨 Emergency SOS",
              body: "${data['name'] ?? 'Someone'} needs immediate help: ${data['threat'] ?? 'Unknown threat'}",
              payload: change.doc.id,
            );
          }
        }
      }
    });

    // 3. Update Officer Location in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      GeoService().startMonitoring();
      GeoService().addListener(() {
        final pos = GeoService().currentPosition;
        if (pos != null) {
          FirebaseFirestore.instance.collection('police').doc(user.uid).update({
            'location': GeoPoint(pos.latitude, pos.longitude),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    }
  }

  void _navigateToAlert(String alertId) async {
    final doc = await FirebaseFirestore.instance.collection('alerts').doc(alertId).get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VictimDetailsScreen(
            victimData: {
              'id': doc.id,
              ...data,
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow content to scroll behind the glossy nav
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
        title: const Text(
          "GeoTour",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_selectedIndex],
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
                    Expanded(child: navItem("Officers", 1)),
                    Expanded(child: navItem("Incidents", 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(String label, int index) {
    bool selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuart,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
