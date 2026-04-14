import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../common/report_viewer_screen.dart';
import '../../widgets/premium_toast.dart';

class TouristProfileScreen extends StatefulWidget {
  const TouristProfileScreen({super.key});

  @override
  State<TouristProfileScreen> createState() => _TouristProfileScreenState();
}

class _TouristProfileScreenState extends State<TouristProfileScreen> {
  bool isLoading = false;
  bool isUploading = false;
  bool _isChanged = false;

  // Cloudinary Configuration
  static const String _cloudName = "dwkswq6b6";
  static const String _uploadPreset = "Medical_Health_Report_Files";

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController travelIdController = TextEditingController();

  final TextEditingController medicationsController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController surgeriesController = TextEditingController();

  final TextEditingController emergencyContactNameController =
      TextEditingController();
  final TextEditingController emergencyContactPhoneController =
      TextEditingController();

  String bloodGroup = "O+";
  String? reportUrl;
  String? reportName;

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('tourists')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final m = data['medicalInfo'] as Map<String, dynamic>?;
        final e = data['emergencyContact'] as Map<String, dynamic>?;

        setState(() {
          nameController.text = data['username'] ?? user.displayName ?? "";
          phoneController.text = data['phone'] ?? "";
          travelIdController.text = data['travelId'] ?? "";

          if (m != null) {
            bloodGroup = m['bloodGroup'] ?? "O+";
            medicationsController.text = m['medications'] ?? "";
            allergiesController.text = m['allergies'] ?? "";
            surgeriesController.text = m['surgeries'] ?? "";
            reportUrl = m['healthReportFile'] ?? m['reportUrl'];
            reportName =
                m['reportName'] ??
                (reportUrl != null ? "Medical_Report" : null);
          }

          if (e != null) {
            emergencyContactNameController.text = e['name'] ?? "";
            emergencyContactPhoneController.text = e['phone'] ?? "";
          }
        });
      }
    }
    setState(() => isLoading = false);
  }

  double _calculateSafetyScore() {
    int totalPoints = 0;
    if (nameController.text.isNotEmpty) totalPoints += 15;
    if (phoneController.text.isNotEmpty) totalPoints += 15;
    if (travelIdController.text.isNotEmpty) totalPoints += 10;
    if (medicationsController.text.isNotEmpty ||
        allergiesController.text.isNotEmpty)
      totalPoints += 20;
    if (emergencyContactNameController.text.isNotEmpty &&
        emergencyContactPhoneController.text.isNotEmpty)
      totalPoints += 20;
    if (reportUrl != null) totalPoints += 20;
    return totalPoints / 100;
  }

  Future<void> _pickAndUploadReport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() => isUploading = true);
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      try {
        final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
        );
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        final response = await request.send();
        if (response.statusCode == 200) {
          final resData = await response.stream.bytesToString();
          final jsonRes = json.decode(resData);
          setState(() {
            reportUrl = jsonRes['secure_url'];
            reportName = fileName;
            _isChanged = true;
          });
          PremiumToast.show(
            context,
            title: "Report Uploaded",
            message: "Your medical document is securely saved.",
            type: ToastType.success,
          );
        } else {
          final resData = await response.stream.bytesToString();
          throw Exception("Cloudinary upload failed: $resData");
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
        PremiumToast.show(
          context,
          title: "Upload Failed",
          message: "Check your internet connection and try again.",
          type: ToastType.error,
        );
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('tourists')
            .doc(user.uid)
            .set({
              'username': nameController.text.trim(),
              'phone': phoneController.text.trim(),
              'travelId': travelIdController.text.trim(),
              'medicalInfo': {
                'bloodGroup': bloodGroup,
                'medications': medicationsController.text.trim(),
                'allergies': allergiesController.text.trim(),
                'surgeries': surgeriesController.text.trim(),
                'healthReportFile': reportUrl,
                'reportName': reportName,
              },
              'emergencyContact': {
                'name': emergencyContactNameController.text.trim(),
                'phone': emergencyContactPhoneController.text.trim(),
              },
              'profileCompleted': _calculateSafetyScore() >= 0.8,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': nameController.text.trim()});

        if (mounted) {
          PremiumToast.show(
            context,
            title: "Profile Saved",
            message: "Your changes have been safely verified.",
            type: ToastType.success,
          );
          setState(() => _isChanged = false);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Save Failed",
            message: "An error occurred. Please try again.",
            type: ToastType.error,
          );
        }
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double safetyScore = _calculateSafetyScore();
    bool isHighlySecure = safetyScore >= 0.8;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Native Style Safety Status Card
            _buildNativeSafetyCard(safetyScore, isHighlySecure),
            const SizedBox(height: 20),

            // Identity Section
            _buildNativeSection("Identity Details", Icons.badge_outlined, [
              _buildNativeInput(
                "User Display Name",
                nameController,
                Icons.person_outline_rounded,
              ),
              _buildNativeInput(
                "Contact Mobile",
                phoneController,
                Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
              _buildNativeInput(
                "Government Travel ID",
                travelIdController,
                Icons.card_membership_rounded,
              ),
            ]),
            const SizedBox(height: 20),

            // Emergency Contacts
            _buildNativeSection(
              "Emergency Response",
              Icons.emergency_outlined,
              [
                _buildNativeInput(
                  "Guardian Name",
                  emergencyContactNameController,
                  Icons.supervisor_account_rounded,
                ),
                _buildNativeInput(
                  "Guardian Phone",
                  emergencyContactPhoneController,
                  Icons.contact_emergency_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medical Profile
            _buildNativeSection(
              "Medical Health Bio",
              Icons.monitor_heart_outlined,
              [
                _buildNativeDropdown(
                  "Blood Group",
                  bloodGroup,
                  bloodGroups,
                  Icons.bloodtype_rounded,
                  (val) {
                    if (val != null) {
                      setState(() {
                        bloodGroup = val;
                        _isChanged = true;
                      });
                    }
                  },
                ),
                _buildNativeInput(
                  "Daily Medications",
                  medicationsController,
                  Icons.medication_rounded,
                  maxLines: 2,
                  hint: "Enter meds...",
                ),
                _buildNativeInput(
                  "Known Allergies",
                  allergiesController,
                  Icons.warning_rounded,
                  maxLines: 2,
                  hint: "Enter allergies...",
                ),
                _buildNativeInput(
                  "Recent Surgeries",
                  surgeriesController,
                  Icons.personal_injury_rounded,
                  maxLines: 2,
                  hint: "Enter history...",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medical Documents
            _buildNativeSection(
              "Safety Documents",
              Icons.file_present_outlined,
              [_buildNativeReportCard()],
            ),
            const SizedBox(height: 32),

            // Bottom Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isChanged ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeSafetyCard(double score, bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F1F1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Safety preparedness",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? "Highly Secure" : "Incomplete",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${(score * 100).toInt()}% Verified",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      "Your safety profile is used by responders in case of emergency.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: score,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFEEEEEE),
                  color: Colors.black,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNativeSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F1F1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children.asMap().entries.map((entry) {
            int idx = entry.key;
            return Column(
              children: [
                entry.value,
                if (idx < children.length - 1)
                  const Divider(height: 32, color: Color(0xFFF1F1F1)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNativeInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
              prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey.shade300),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (_) => setState(() => _isChanged = true),
          ),
        ),
      ],
    );
  }

  Widget _buildNativeDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blueGrey.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: Container(),
                  items: items
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNativeReportCard() {
    return Column(
      children: [
        if (reportUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportName ?? "Medical_Record.pdf",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Secure Document Loaded",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportViewerScreen(url: reportUrl!, title: "Report"),
                    ),
                  ),
                  child: const Text(
                    "VIEW",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "No medical report. Responders need this.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isUploading ? null : _pickAndUploadReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    reportUrl != null ? "REPLACE REPORT" : "UPLOAD REPORT",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
