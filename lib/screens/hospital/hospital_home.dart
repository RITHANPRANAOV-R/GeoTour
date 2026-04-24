import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/hospital_service.dart';
import 'patient_details.dart';

class HospitalHomeContent extends StatefulWidget {
  const HospitalHomeContent({super.key});

  @override
  State<HospitalHomeContent> createState() => _HospitalHomeContentState();
}

class _HospitalHomeContentState extends State<HospitalHomeContent> {
  String _activeFilter = "Unaccepted";
  final List<String> _filters = ["Unaccepted", "Ongoing", "Extreme", "All"];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final hospitalService = HospitalService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance
                          .collection('hospitals')
                          .doc(user.uid)
                          .snapshots()
                    : null,
                builder: (context, snapshot) {
                  String name = "Hospital";
                  bool isAvailable = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['hospitalName'] ?? "Hospital";
                    isAvailable = data['isAvailable'] ?? false;
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Welcome, $name",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isAvailable ? "Active" : "Offline",
                                  style: TextStyle(
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CupertinoSwitch(
                                  value: isAvailable,
                                  onChanged: (value) async {
                                    if (user != null) {
                                      await hospitalService
                                          .updateHospitalStatus(
                                            user.uid,
                                            value,
                                          );
                                    }
                                  },
                                  activeTrackColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.map((f) {
                    bool isActive = _activeFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.redAccent : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? Colors.redAccent : Colors.black12),
                          boxShadow: [
                            if (isActive)
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Text(
                          f.toUpperCase(),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Medical Risks",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: user != null ? hospitalService.getGlobalHospitalAlertsStream(user.uid) : null,
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Text(
                        "Total: $count",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: user != null
                  ? hospitalService.getGlobalHospitalAlertsStream(user.uid)
                  : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Failed to load alerts",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    ),
                  );
                }

                var alerts = snapshot.data?.docs ?? [];

                // Filter logic
                if (_activeFilter == "Unaccepted") {
                  alerts = alerts.where((d) => 
                    (d.data() as Map)['status'] == 'pending'
                  ).toList();
                } else if (_activeFilter == "Ongoing") {
                  alerts = alerts.where((d) => 
                    (d.data() as Map)['status'] == 'ongoing'
                  ).toList();
                } else if (_activeFilter == "Extreme") {
                  alerts = alerts.where((d) => 
                    (d.data() as Map)['riskLevel']?.toString().toLowerCase() == 'extreme'
                  ).toList();
                }

                // Manual Sort (latest first) to avoid Firestore index requirement
                final sortedAlerts = alerts.toList()
                  ..sort((a, b) {
                    final aTime =
                        (a.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    final bTime =
                        (b.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                if (sortedAlerts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No alerts found for this filter.",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedAlerts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final alertDoc = sortedAlerts[index];
                    final data = alertDoc.data() as Map<String, dynamic>;

                    String timeText = "Just now";
                    if (data['timestamp'] != null) {
                      final timestamp = data['timestamp'] as Timestamp;
                      final diff = DateTime.now().difference(
                        timestamp.toDate(),
                      );
                      if (diff.inMinutes < 60) {
                        timeText = "Triggered ${diff.inMinutes}m ago";
                      } else {
                        timeText = "Triggered ${diff.inHours}h ago";
                      }
                    }

                    return RepaintBoundary(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F1F1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 20,
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
                                      alertData: {...data, 'id': alertDoc.id},
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
                                      color: _getRiskColor(data['riskLevel']),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.grey.shade100,
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['victimName'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 17,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeText,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade500,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getRiskColor(
                                                  data['riskLevel'],
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                data['riskLevel']
                                                        ?.toUpperCase() ??
                                                    'HIGH',
                                                style: TextStyle(
                                                  color: _getRiskColor(
                                                    data['riskLevel'],
                                                  ),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 10,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Colors.grey.shade300,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'extreme':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}
