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
            ElevatedButton(
              onPressed: (isAvailable && !isOnMission) ? onAssign : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (isAvailable && !isOnMission) ? Colors.black : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
              ),
              child: Text(isOnMission ? "On Mission" : (isAvailable ? "Assign" : "Offline")),
            ),
          ],
        ),
      ),
    );
  }
}
