import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncidentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> incident;

  const IncidentDetailsScreen({super.key, required this.incident});

  Color _getStatusColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('extreme') || t.contains('threat') || t.contains('sos')) {
      return const Color(0xFFFF3B30); // Danger Red
    }
    if (t.contains('high') || t.contains('accident')) {
      return const Color(0xFFFF9500); // Warning Orange
    }
    if (t.contains('medium') || t.contains('violation')) {
      return const Color(0xFF5856D6); // Purple
    }
    if (t.contains('low') || t.contains('medical')) {
      return const Color(0xFF007AFF); // Info Blue
    }
    if (t.contains('safe') || t.contains('stable')) {
      return const Color(0xFF34C759); // Success Green
    }
    return Colors.blueGrey;
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('extreme') || t.contains('threat') || t.contains('sos')) {
      return Icons.emergency_rounded;
    }
    if (t.contains('accident')) {
      return Icons.car_crash_rounded;
    }
    if (t.contains('violation')) {
      return Icons.gpp_bad_rounded;
    }
    if (t.contains('medical')) {
      return Icons.medical_services_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final type = incident['type'] ?? 'General';
    final typeColor = _getStatusColor(type);
    final timestamp = incident['timestamp'] != null 
        ? DateTime.parse(incident['timestamp']) 
        : DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(timestamp);
    final formattedTime = DateFormat('hh:mm a').format(timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Incident Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor.withValues(alpha: 0.15),
                    typeColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: typeColor.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color: typeColor,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "ID: ${incident['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}",
                      style: TextStyle(
                        color: typeColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle("REPORTER INFORMATION"),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.person_outline_rounded, "Victim Name", incident['user'] ?? 'Unknown'),
              const Divider(height: 32, color: Color(0xFFF1F1F1)),
              _buildInfoRow(Icons.history_toggle_off_rounded, "Logged On", "$formattedDate at $formattedTime"),
            ]),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("INCIDENT SUMMARY"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        "PRIORITY: ${type.toUpperCase()}",
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F1F1)),
              ),
              child: Text(
                incident['details'] ?? 'No additional details provided for this incident.',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

            _buildSectionTitle("RESPONSE TEAM"),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.security_rounded, "Officer Assigned", incident['officer'] ?? 'Dispatching...'),
            ]),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "CLOSE REPORT",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.blueGrey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
