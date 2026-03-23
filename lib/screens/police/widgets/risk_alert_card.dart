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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onTap: onTap,
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "Triggered $timeText",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRiskColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                riskLevel.toUpperCase(),
                style: TextStyle(
                  color: _getRiskColor(),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (acceptedBy != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(Icons.check_circle_rounded, color: Colors.blue.shade600, size: 14),
                   const SizedBox(width: 4),
                   Text(
                     "ASSIGNED",
                     style: TextStyle(
                       color: Colors.blue.shade700,
                       fontWeight: FontWeight.w800,
                       fontSize: 10,
                     ),
                   ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
