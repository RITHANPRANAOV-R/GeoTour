import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/hospital_service.dart';
import 'patient_details.dart';

class HospitalCasesScreen extends StatelessWidget {
  const HospitalCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final hospitalService = HospitalService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Medical Cases",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: user != null ? hospitalService.getHospitalCasesStream(user.uid) : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            "Failed to load cases",
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  );
                }

                final cases = snapshot.data?.docs ?? [];
                
                // Manual Sort (latest first) to avoid Firestore index requirement
                final sortedCases = cases.toList()..sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (sortedCases.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            "No case history found.",
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: sortedCases.map((caseDoc) {
                    final data = caseDoc.data() as Map<String, dynamic>;
                    
                    String dateText = "N/A";
                    if (data['timestamp'] != null) {
                      final timestamp = data['timestamp'] as Timestamp;
                      final date = timestamp.toDate();
                      dateText = "${_getMonth(date.month)} ${date.day}, ${date.year}";
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F1F1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailsScreen(
                                    alertData: {...data, 'id': caseDoc.id},
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 6,
                                    color: _getStatusColor(data['status']),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey.shade100,
                                            child: Icon(Icons.person_rounded, color: Colors.grey.shade400, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data['victimName'] ?? 'Unknown',
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                                                ),
                                                Text(
                                                  dateText,
                                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _buildStatusBadge(data['status']),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          data['status'] == 'completed' && data['caseDescription'] != null
                                              ? "Summary: ${data['caseDescription']}"
                                              : (data['medicalInfo'] ?? 'No description provided for this medical case.'),
                                          style: TextStyle(
                                            color: data['status'] == 'completed' ? Colors.green.shade700 : Colors.grey.shade600,
                                            fontSize: 13,
                                            height: 1.4,
                                            fontWeight: data['status'] == 'completed' ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color = Colors.grey;
    String label = status?.toUpperCase() ?? 'UNKNOWN';

    switch (status?.toLowerCase()) {
      case 'ongoing':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'transferred':
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'ongoing': return Colors.blue;
      case 'completed': return Colors.green;
      case 'transferred': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
