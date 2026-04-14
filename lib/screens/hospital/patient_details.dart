import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/report_viewer_screen.dart';
import '../../services/file_service.dart';
import '../../models/hospital_model.dart';
import '../../services/hospital_service.dart';
import '../../widgets/premium_toast.dart';
import '../../services/auth_service.dart';
import 'widgets/transfer_dialog.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> alertData;
  const PatientDetailsScreen({super.key, required this.alertData});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final HospitalService _hospitalService = HospitalService();
  final user = AuthService().currentUser;
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final victimId = widget.alertData['victimId'];
    final status = widget.alertData['status'] ?? 'pending';
    final riskLevel = widget.alertData['riskLevel'] ?? 'High';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getRiskColor(riskLevel).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              riskLevel,
              style: TextStyle(
                color: _getRiskColor(riskLevel),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('tourists')
            .doc(victimId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final touristData =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final medicalInfo =
              touristData['medicalInfo'] as Map<String, dynamic>? ?? {};
          final phone = touristData['phone'] ?? 'N/A';
          final emergencyContacts = touristData['emergencyContacts'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.black12,
                  ),
                ),
                const SizedBox(height: 32),
                _buildDetailField(
                  "Patient Name",
                  widget.alertData['victimName'] ?? 'Unknown',
                ),
                _buildDetailField(
                  "Current Medications",
                  medicalInfo['medications'] ?? 'N/A',
                ),
                _buildDetailField(
                  "Allergies",
                  medicalInfo['allergies'] ?? 'N/A',
                ),
                _buildDetailField(
                  "Surgeries",
                  medicalInfo['surgeries'] ?? 'N/A',
                ),
                _buildReportField(
                  "Medical Report",
                  medicalInfo['healthReportFile'] ?? 'N/A',
                ),
                _buildDetailField("Contact Number", phone, isPhone: true),
                _buildDetailField("Emergency Contacts", emergencyContacts),
                const SizedBox(height: 40),
                if (status == 'pending') ...[
                  ElevatedButton(
                    onPressed: isLoading ? null : _acceptCase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Confirm Case",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ] else if (status == 'ongoing') ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Treatment Summary",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            "Enter treatment details and patient status...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _transferCase,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Transfer",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _descriptionController,
                          builder: (context, value, child) {
                            final bool canComplete =
                                value.text.trim().isNotEmpty && !isLoading;
                            return ElevatedButton(
                              onPressed: canComplete ? _completeCase : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.grey.shade300,
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Complete",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Column(
                    children: [
                      if (widget.alertData['caseDescription'] != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Treatment Summary",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            widget.alertData['caseDescription'],
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            "CASE ${status.toUpperCase()}",
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailField(String label, String value, {bool isPhone = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isPhone && value != 'N/A')
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "Call",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildReportField(String label, String fileUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fileUrl != 'N/A')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 22,
                        color: Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportViewerScreen(
                              url: fileUrl,
                              title: "Patient Report",
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 22,
                        color: Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final isPdf =
                            fileUrl.toLowerCase().contains('.pdf') ||
                            fileUrl.contains('/raw/upload/');
                        final fileName =
                            "Medical_Report_${DateTime.now().millisecondsSinceEpoch}.${isPdf ? 'pdf' : 'jpg'}";
                        FileService.downloadFile(
                          context: context,
                          url: fileUrl,
                          fileName: fileName,
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fileUrl == 'N/A'
                ? 'No report uploaded'
                : 'Click "eye" icon to view report',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: fileUrl == 'N/A' ? Colors.grey : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCase() async {
    setState(() => isLoading = true);
    try {
      if (user != null) {
        await _hospitalService.acceptCase(user!.uid, widget.alertData['id']);
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Case Confirmed",
            message: "You have securely accepted this emergency.",
            type: ToastType.success,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Action Failed",
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _completeCase() async {
    final summary = _descriptionController.text.trim();
    if (summary.isEmpty) return;

    setState(() => isLoading = true);
    try {
      if (user != null) {
        await _hospitalService.completeCase(
          user!.uid,
          widget.alertData['id'],
          summary,
        );
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Case Completed",
            message: "Patient details filed successfully.",
            type: ToastType.success,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Action Failed",
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _transferCase() async {
    if (user == null) return;

    final result = await showDialog<HospitalModel>(
      context: context,
      builder: (context) => TransferDialog(currentHospitalId: user!.uid),
    );

    if (result != null) {
      setState(() => isLoading = true);
      try {
        await _hospitalService.transferCase(
          fromHospitalId: user!.uid,
          toHospitalId: result.uid,
          alertId: widget.alertData['id'],
          alertData: widget.alertData,
        );
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Case Transferred",
            message: "Alert passed to ${result.name}",
            type: ToastType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Transfer Error",
            message: e.toString(),
            type: ToastType.error,
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'transferred':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
