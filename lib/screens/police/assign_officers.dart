import 'package:flutter/material.dart';
import '../../services/police_service.dart';
import 'widgets/officer_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignOfficersScreen extends StatefulWidget {
  const AssignOfficersScreen({super.key});

  @override
  State<AssignOfficersScreen> createState() => _AssignOfficersScreenState();
}

class _AssignOfficersScreenState extends State<AssignOfficersScreen> {
  bool showAvailableOnly = false;

  @override
  Widget build(BuildContext context) {
    final PoliceService policeService = PoliceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Officer"),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilterChip(
              label: const Text("Available Only"),
              selected: showAvailableOnly,
              onSelected: (value) {
                setState(() {
                  showAvailableOnly = value;
                });
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: policeService.getOfficersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No officers found."));
          }

          var officers = snapshot.data!.docs;
          
          if (showAvailableOnly) {
            officers = officers.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isAvailable'] == true && data['status'] != 'on_mission';
            }).toList();
          }

          if (officers.isEmpty) {
            return const Center(child: Text("No available officers matched criteria."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: officers.length,
            itemBuilder: (context, index) {
              final officerDoc = officers[index];
              final officer = officerDoc.data() as Map<String, dynamic>;

              return OfficerCard(
                name: officer['name'] ?? 'Unknown',
                rank: officer['badgeNumber'] != null ? "Badge: ${officer['badgeNumber']}" : "Officer",
                isAvailable: officer['isAvailable'] ?? false,
                isOnMission: officer['status'] == 'on_mission',
                onAssign: () async {
                  // Logic to assign this officer to an incident would go here
                  // For now, toggle their status to on_mission
                  await policeService.updateOfficerStatus(
                    officerDoc.id,
                    'on_mission',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Assigned ${officer['name']}")),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
