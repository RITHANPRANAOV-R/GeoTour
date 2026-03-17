import 'package:flutter/material.dart';

class RiskAlertCard extends StatelessWidget {
  final String name;
  final String timeText;
  final String riskLevel;
  final String? acceptedBy;
  final String? acceptedByName;
  final VoidCallback onTap;

  const RiskAlertCard({
    super.key,
    required this.name,
    required this.timeText,
    required this.riskLevel,
    this.acceptedBy,
    this.acceptedByName,
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
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
            if (acceptedBy != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "ASSIGNED",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
