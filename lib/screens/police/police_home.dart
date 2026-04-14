import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/police_service.dart';
import 'widgets/risk_alert_card.dart';
import 'victim_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PoliceHomeScreen extends StatelessWidget {
  const PoliceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PoliceService policeService = PoliceService();
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? policeService.getOfficerProfileStream(user.uid)
                    : null,
                builder: (context, snapshot) {
                  String name = "Officer";
                  String status = "offline";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? "Officer";
                    status =
                        data['status'] ??
                        (data['isAvailable'] == true ? 'available' : 'offline');
                  }
                  bool isAvailable = status == 'available';
                  bool onMission = status == 'on_mission';

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Welcome, $name",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Recent Risk Alerts",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: policeService.getAlertsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("No active risk alerts.")),
                  );
                }

                final alerts = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alertDoc = alerts[index];
                    final alert = alertDoc.data() as Map<String, dynamic>;

                    String timeText = "Just now";
                    if (alert['timestamp'] != null) {
                      final timestamp = alert['timestamp'] as Timestamp;
                      final diff = DateTime.now().difference(
                        timestamp.toDate(),
                      );
                      if (diff.inMinutes < 60) {
                        timeText = "${diff.inMinutes}m ago";
                      } else {
                        timeText = "${diff.inHours}h ago";
                      }
                    }

                    return RiskAlertCard(
                      name: alert['name'] ?? 'Unknown',
                      timeText: timeText,
                      riskLevel: alert['riskLevel'] ?? 'High',
                      acceptedBy: alert['acceptedBy'],
                      acceptedByName: alert['acceptedByName'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VictimDetailsScreen(
                              victimData: {
                                'id': alertDoc.id,
                                'userId': alert['userId'] ?? '',
                                'name': alert['name'] ?? 'Unknown',
                                'riskLevel': alert['riskLevel'] ?? 'High',
                                'phone': alert['phone'] ?? 'N/A',
                                'contacts': alert['contacts'] ?? 'N/A',
                                'threat': alert['threat'] ?? 'N/A',
                                'acceptedBy': alert['acceptedBy'] ?? '',
                                'acceptedByName': alert['acceptedByName'] ?? '',
                              },
                            ),
                          ),
                        );
                      },
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
