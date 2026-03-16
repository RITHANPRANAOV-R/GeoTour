import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("GeoTour"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<DocumentSnapshot>(
                future: user != null ? policeService.getOfficerProfile(user.uid) : null,
                builder: (context, snapshot) {
                  String name = "Officer";
                  bool isAvailable = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? "Officer";
                    isAvailable = data['isAvailable'] ?? false;
                  }
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Welcome, $name",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Switch(
                                value: isAvailable,
                                onChanged: (value) async {
                                  if (user != null) {
                                    await policeService.updateAvailability(user.uid, value);
                                    setState(() {
                                      isAvailable = value;
                                    });
                                  }
                                },
                                activeColor: Colors.green,
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isAvailable ? "Available" : "Offline",
                            style: TextStyle(
                              color: isAvailable ? Colors.green : Colors.red,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Recent Risk Alerts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
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
                    
                    // Handle timestamp properly
                    String timeText = "Just now";
                    if (alert['timestamp'] != null) {
                      final timestamp = alert['timestamp'] as Timestamp;
                      final diff = DateTime.now().difference(timestamp.toDate());
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VictimDetailsScreen(
                              victimData: {
                                'id': alertDoc.id,
                                'name': alert['name'] ?? 'Unknown',
                                'riskLevel': alert['riskLevel'] ?? 'High',
                                'phone': alert['phone'] ?? 'N/A',
                                'contacts': alert['contacts'] ?? 'N/A',
                                'threat': alert['threat'] ?? 'N/A',
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
