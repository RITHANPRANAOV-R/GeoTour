import 'package:flutter/material.dart';

class OfficerCard extends StatelessWidget {
  final String name;
  final String rank;
  final bool isAvailable;
  final bool isOnMission;
  final VoidCallback onAssign;

  const OfficerCard({
    super.key,
    required this.name,
    required this.rank,
    this.isAvailable = false,
    this.isOnMission = false,
    required this.onAssign,
  });

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.person_rounded, color: Colors.blue.shade700, size: 28),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade500 : Colors.red.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rank,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isOnMission 
                    ? Colors.orange.shade50 
                    : (isAvailable ? Colors.green.shade50 : Colors.red.shade50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOnMission ? "On Mission" : (isAvailable ? "Available" : "Offline"),
                style: TextStyle(
                  color: isOnMission 
                      ? Colors.orange.shade700 
                      : (isAvailable ? Colors.green.shade700 : Colors.red.shade700),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
