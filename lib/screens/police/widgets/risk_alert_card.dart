import 'package:flutter/material.dart';

class RiskAlertCard extends StatelessWidget {
  final String name;
  final String timeText;
  final String riskLevel;
  final VoidCallback onTap;

  const RiskAlertCard({
    super.key,
    required this.name,
    required this.timeText,
    required this.riskLevel,
    required this.onTap,
  });

  Color _getRiskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'extreme':
        return Colors.red;
      case 'high':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          "Triggered $timeText",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRiskColor(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            riskLevel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
