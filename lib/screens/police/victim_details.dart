import 'package:flutter/material.dart';
import '../../services/police_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VictimDetailsScreen extends StatelessWidget {
  final Map<String, String> victimData;

  const VictimDetailsScreen({
    super.key,
    required this.victimData,
  });

  @override
  Widget build(BuildContext context) {
    final PoliceService policeService = PoliceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: Text(victimData['riskLevel'] ?? 'Extreme'),
              backgroundColor: Colors.red,
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(),
              const SizedBox(height: 20),
              const Text(
                "Map View",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildMapPlaceholder(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) {
            final user = FirebaseAuth.instance.currentUser;
            final String acceptedBy = victimData['acceptedBy'] ?? '';
            final String acceptedByName = victimData['acceptedByName'] ?? '';
            final String alertId = victimData['id'] ?? '';
            
            if (acceptedBy.isEmpty) {
              // Not accepted yet
              return ElevatedButton(
                onPressed: () async {
                  if (user == null) return;
                  
                  // Get current officer name (we can pass it or fetch)
                  final officerDoc = await policeService.getOfficerProfile(user.uid);
                  final officerName = (officerDoc.data() as Map<String, dynamic>?)?['name'] ?? "Officer";

                  bool success = await policeService.acceptAlert(
                    alertId: alertId,
                    officerId: user.uid,
                    officerName: officerName,
                  );

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Alert accepted! You are now on mission.")),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not accept. Already assigned or error.")),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Accept Alert", style: TextStyle(fontSize: 18)),
              );
            } else if (acceptedBy == user?.uid) {
              // Assigned to current user
              return ElevatedButton(
                onPressed: () async {
                  await policeService.completeMission(
                    alertId: alertId,
                    officerId: user!.uid,
                    alertData: Map<String, dynamic>.from(victimData),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mission completed and moved to incidents.")),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Complete Mission", style: TextStyle(fontSize: 18)),
              );
            } else {
              // Assigned to someone else
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "ASSIGNED TO $acceptedByName",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow("Patient Name", victimData['name'] ?? "Atlee"),
            const Divider(),
            _buildInfoRow("Emergency Contacts", "Kumar\nF/O Atlee\n9644329933"),
            const Divider(),
            _buildInfoRow("Threat Occurred", "Entered High Risk Zone"),
            const Divider(),
            _buildInfoRow("Contact Number", "9770012446"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Initializing Map Services...",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Waiting for API connection",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
