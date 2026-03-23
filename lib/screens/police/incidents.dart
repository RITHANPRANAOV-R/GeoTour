import 'package:flutter/material.dart';
import '../../services/police_service.dart';
import 'widgets/incident_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PoliceService policeService = PoliceService();

    return StreamBuilder<QuerySnapshot>(
      stream: policeService.getIncidentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No incidents recorded yet."));
        }

        final incidents = snapshot.data!.docs;

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    "Incidents",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100), // Padding for nav bar
                itemCount: incidents.length,
                itemBuilder: (context, index) {
                  final incidentDoc = incidents[index];
                  final incident = incidentDoc.data() as Map<String, dynamic>;

                  // Handle timestamp formatting
                  String dateText = "";
                  if (incident['timestamp'] != null) {
                    final timestamp = incident['timestamp'] as Timestamp;
                    final date = timestamp.toDate();
                    dateText = "${date.day}/${date.month}/${date.year}";
                  } else if (incident['date'] != null) {
                    dateText = incident['date'];
                  }

                  return IncidentCard(
                    victimName: incident['victimName'] ?? 'Unknown',
                    summary: incident['summary'] ?? 'No details.',
                    date: dateText,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
