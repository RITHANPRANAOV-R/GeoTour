import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/police_service.dart';
import 'victim_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/risk_alert_card.dart';

class PoliceHomeScreen extends StatefulWidget {
  const PoliceHomeScreen({super.key});

  @override
  State<PoliceHomeScreen> createState() => _PoliceHomeScreenState();
}

class _PoliceHomeScreenState extends State<PoliceHomeScreen> {
  String _activeFilter = "Unaccepted";
  final List<String> _filters = ["Unaccepted", "Accepted", "High", "All"];

  @override
  Widget build(BuildContext context) {
    final PoliceService policeService = PoliceService();
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Welcome and Duty Toggle
            StreamBuilder<DocumentSnapshot>(
              stream: policeService.getOfficerProfileStream(user?.uid ?? ""),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final name = data?['name']?.toString().split(' ').first ?? "Officer";
                final isAvailable = data?['isAvailable'] == true;
                final onMission = data?['status'] == 'on_mission';

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Welcome, $name",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CupertinoSwitch(
                          value: isAvailable || onMission,
                          onChanged: onMission
                              ? null
                              : (value) async {
                                  if (user != null) {
                                    await policeService.updateAvailability(
                                      user.uid,
                                      value,
                                    );
                                  }
                                },
                          activeTrackColor: onMission
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          onMission
                              ? "On Mission"
                              : (isAvailable ? "Available" : "Offline"),
                          style: TextStyle(
                            color: onMission
                                ? Colors.orange
                                : (isAvailable ? Colors.green : Colors.red),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            /// ACTIVE ALERTS LIST
            const Text(
              "Active Incidents",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            /// Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((f) {
                  bool isActive = _activeFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _activeFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? Colors.black : Colors.black12),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Text(
                        f.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: policeService.getAlertsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                  );
                }

                var alerts = snapshot.data?.docs ?? [];

                // Filter logic
                if (_activeFilter == "Unaccepted") {
                  alerts = alerts.where((d) => (d.data() as Map)['status'] == 'pending').toList();
                } else if (_activeFilter == "Accepted") {
                  alerts = alerts.where((d) => (d.data() as Map)['status'] == 'assigned').toList();
                } else if (_activeFilter == "High") {
                  alerts = alerts.where((d) => (d.data() as Map)['riskLevel']?.toString().toUpperCase() == 'HIGH' || (d.data() as Map)['riskLevel']?.toString().toUpperCase() == 'EXTREME').toList();
                }

                // Sort by timestamp — newest first
                alerts.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (alerts.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          "No incidents found",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = alerts[index].data() as Map<String, dynamic>;
                    final alertId = alerts[index].id;
                    
                    String timeText = "Just now";
                    if (data['timestamp'] != null) {
                      final timestamp = data['timestamp'] as Timestamp;
                      final diff = DateTime.now().difference(
                        timestamp.toDate(),
                      );
                      if (diff.inMinutes < 60) {
                        timeText = "${diff.inMinutes}m ago";
                      } else {
                        timeText = "${diff.inHours}h ago";
                      }
                    }

                    return RepaintBoundary(
                      child: RiskAlertCard(
                        name: data['name'] ?? data['victimName'] ?? "Emergency Alert",
                        timeText: timeText,
                        riskLevel: data['riskLevel']?.toString() ?? "Low",
                        acceptedBy: data['acceptedBy'],
                        acceptedByName: data['acceptedByName'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VictimDetailsScreen(
                                victimData: {'id': alertId, ...data},
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }


}
