import 'package:flutter/material.dart';
import '../../services/police_service.dart';
import 'widgets/incident_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PoliceService policeService = PoliceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incidents"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: policeService.getIncidentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No incidents recorded yet."));
          }

          final incidents = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incidentDoc = incidents[index];
              final incident = incidentDoc.data() as Map<String, dynamic>;

              return IncidentCard(
                victimName: incident['victimName'] ?? 'Unknown',
                summary: incident['summary'] ?? 'No details.',
                date: incident['date'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}
