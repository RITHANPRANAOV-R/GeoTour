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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, color: Colors.blue.shade900),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    rank,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOnMission 
                    ? Colors.orange.shade100 
                    : (isAvailable ? Colors.green.shade100 : Colors.red.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOnMission ? "On Mission" : (isAvailable ? "Available" : "Offline"),
                style: TextStyle(
                  color: isOnMission 
                      ? Colors.orange.shade900 
                      : (isAvailable ? Colors.green.shade900 : Colors.red.shade900),
                  fontWeight: FontWeight.bold,
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
