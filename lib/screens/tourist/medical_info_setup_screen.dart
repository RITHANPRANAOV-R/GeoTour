import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/premium_toast.dart';

class MedicalInfoSetupScreen extends StatefulWidget {
  const MedicalInfoSetupScreen({super.key});

  @override
  State<MedicalInfoSetupScreen> createState() => _MedicalInfoSetupScreenState();
}

class _MedicalInfoSetupScreenState extends State<MedicalInfoSetupScreen> {
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController medicationsController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController surgeriesController = TextEditingController();

  String? selectedBloodGroup;
  String? selectedFileName;
  String? selectedFilePath;
  dynamic selectedFileBytes; // For Web support

  bool isLoading = false;

  // Cloudinary Configuration
  // TODO: Replace with your Cloudinary credentials from the dashboard
  static const String _cloudName = "dwkswq6b6";
  static const String _uploadPreset = "Medical_Health_Report_Files";

  @override
  void dispose() {
    medicationsController.dispose();
    allergiesController.dispose();
    surgeriesController.dispose();
    super.dispose();
  }

  Future<void> saveMedicalDetails() async {
    if (selectedBloodGroup == null) {
      PremiumToast.show(
        context,
        title: "Medical Record",
        message:
            "Please select your blood group to ensure emergency readiness.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    String? healthReportUrl = selectedFileName;

    try {
      // 1. Upload file if selected
      if (selectedFilePath != null || selectedFileBytes != null) {
        final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/$_cloudName/auto/upload",
        );

        final request = http.MultipartRequest("POST", url)
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = 'medical_reports';

        if (selectedFilePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath('file', selectedFilePath!),
          );
        } else {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              selectedFileBytes!,
              filename: selectedFileName,
            ),
          );
        }

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          healthReportUrl = jsonResponse['secure_url'];
        } else {
          final errorMsg =
              jsonResponse['error']?['message'] ?? "Unknown Cloudinary error";
          throw Exception(
            "Cloudinary Error (${response.statusCode}): $errorMsg",
          );
        }
      }

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection("tourists").doc(user.uid).set(
        {
          "medicalInfo": {
            "bloodGroup": selectedBloodGroup,
            "medications": medicationsController.text.trim(),
            "allergies": allergiesController.text.trim(),
            "surgeries": surgeriesController.text.trim(),
            "healthReportFile": healthReportUrl,
          },
          "updatedAt": DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      setState(() => isLoading = false);

      if (mounted) {
        Navigator.pushReplacementNamed(context, "/touristHome");
      }
    } catch (e) {
      setState(() => isLoading = false);
      String errorMessage = e.toString();

      // Provide user-friendly guidance for Cloudinary errors
      if (errorMessage.contains("YOUR_CLOUD_NAME")) {
        errorMessage =
            "Cloudinary credentials not set. Please update the code with your Cloud Name and Preset.";
      }

      if (mounted) {
        PremiumToast.show(
          context,
          title: "Setup Error",
          message: errorMessage,
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        selectedFilePath = result.files.single.path;
        selectedFileBytes = result.files.single.bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Geotour",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                "AI-powered tourist safety with\nreal-time geo-intelligence",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Setup your Medical Info",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFFEEEEEE),
                      child: const Icon(
                        Icons.person_outline,
                        size: 50,
                        color: Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    _buildBloodGroupDropdown(),
                    _buildField(
                      "Current Medications",
                      "If any",
                      medicationsController,
                    ),
                    _buildField("Allergies", "If any", allergiesController),
                    _buildField("Surgeries", "If any", surgeriesController),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Health Report",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              selectedFileName != null
                                  ? Icons.check_circle_outline
                                  : Icons.file_copy_outlined,
                              color: selectedFileName != null
                                  ? Colors.green
                                  : Colors.black38,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedFileName ??
                                  "Click to Upload your health report",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedFileName != null
                                    ? Colors.black
                                    : Colors.black38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveMedicalDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Finish Setup",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Blood Group *",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: selectedBloodGroup,
          onChanged: (value) {
            setState(() {
              selectedBloodGroup = value;
            });
          },
          items: [
            "A+",
            "A-",
            "B+",
            "B-",
            "O+",
            "O-",
            "AB+",
            "AB-",
          ].map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
          decoration: InputDecoration(
            hintText: "Select blood group",
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFEEEEEE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFEEEEEE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
