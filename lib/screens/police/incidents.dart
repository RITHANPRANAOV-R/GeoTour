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
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // Padding for nav bar
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
                    onTap: () {
                      _showIncidentDetails(context, incident, dateText);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showIncidentDetails(
    BuildContext context,
    Map<String, dynamic> incident,
    String dateText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.local_police_rounded,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Incident Details",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          "Victim",
                          incident['victimName'] ?? 'Unknown',
                          Icons.person_outline_rounded,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        _buildDetailRow(
                          "Date",
                          dateText,
                          Icons.calendar_today_rounded,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        _buildDetailRow(
                          "Risk Level",
                          incident['riskLevel'] ?? 'None',
                          Icons.warning_amber_rounded,
                          isRisk: true,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        _buildDetailRow(
                          "Assigned",
                          incident['officerName'] ?? 'Unassigned',
                          Icons.badge_outlined,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        _buildDetailRow(
                          "Status",
                          (incident['status'] ?? 'Completed')
                              .toString()
                              .toUpperCase(),
                          Icons.info_outline_rounded,
                          isStatus: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      incident['summary'] ??
                          incident['threat'] ??
                          'No summary available.',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.6,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isRisk = false,
    bool isStatus = false,
  }) {
    Color valueColor = Colors.black87;
    if (isRisk) {
      final v = value.toLowerCase();
      valueColor =
          v.contains('high') || v.contains('extreme')
              ? Colors.red
              : (v.contains('medium') ? Colors.orange : Colors.green);
    } else if (isStatus) {
      valueColor =
          value.toLowerCase() == 'completed' ? Colors.green : Colors.blue;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (isRisk || isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
      ],
    );
  }
}
