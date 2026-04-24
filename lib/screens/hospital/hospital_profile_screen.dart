import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/premium_toast.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  bool isLoading = false;
  bool _isChanged = false;

  // Controllers
  final TextEditingController hospitalNameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController erPhoneController = TextEditingController();
  final TextEditingController ambulanceNoController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String category = "General / Multi-Specialty";
  final List<String> categories = [
    "General / Multi-Specialty",
    "Cardiology Speciality",
    "Trauma & Emergency Center",
    "Gastroenterology",
    "Children/Pediatrics",
    "Eye Hospital",
    "Other Speciality",
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
          .collection('hospitals')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          hospitalNameController.text = data['hospitalName'] ?? "";
          licenseController.text = data['licenseNumber'] ?? "";
          category = data['category'] ?? "General / Multi-Specialty";
          erPhoneController.text = data['emergencyPhone'] ?? "";
          ambulanceNoController.text = data['ambulanceNumber'] ?? "";
          cityController.text = data['city'] ?? "";
          addressController.text = data['fullAddress'] ?? "";
          adminNameController.text = data['adminName'] ?? "";
          emailController.text = data['officialEmail'] ?? "";
        });
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (hospitalNameController.text.isEmpty ||
        licenseController.text.isEmpty ||
        erPhoneController.text.isEmpty) {
      PremiumToast.show(
        context,
        title: "Missing Information",
        message: "Name, License, and ER Phone are required.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('hospitals')
            .doc(user.uid)
            .set({
              'hospitalName': hospitalNameController.text.trim(),
              'licenseNumber': licenseController.text.trim(),
              'category': category,
              'emergencyPhone': erPhoneController.text.trim(),
              'ambulanceNumber': ambulanceNoController.text.trim(),
              'city': cityController.text.trim(),
              'fullAddress': addressController.text.trim(),
              'adminName': adminNameController.text.trim(),
              'officialEmail': emailController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // Sync with base users collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': hospitalNameController.text.trim()});

        if (mounted) {
          PremiumToast.show(
            context,
            title: "Facility Data Saved",
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
          "Facility Profile",
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
          children: [
            // Hospital Info Card
            _buildNativeSection(
              "Facility Overview",
              Icons.local_hospital_outlined,
              [
                _buildNativeInput(
                  "Hospital Name",
                  hospitalNameController,
                  Icons.business_outlined,
                ),
                _buildNativeInput(
                  "License / Registration",
                  licenseController,
                  Icons.verified_user_outlined,
                ),
                _buildNativeDropdown(
                  "Speciality Category",
                  category,
                  categories,
                  Icons.category_outlined,
                  (val) {
                    if (val != null) {
                      setState(() {
                        category = val;
                        _isChanged = true;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Coverage / Emergency Section
            _buildNativeSection(
              "Emergency Readiness",
              Icons.emergency_outlined,
              [
                _buildNativeInput(
                  "ER Direct Line",
                  erPhoneController,
                  Icons.phone_callback_rounded,
                  keyboardType: TextInputType.phone,
                ),
                _buildNativeInput(
                  "Ambulance Service",
                  ambulanceNoController,
                  Icons.medical_services_rounded,
                  keyboardType: TextInputType.phone,
                ),
                _buildNativeInput(
                  "Official Admin Email",
                  emailController,
                  Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Location Section
            _buildNativeSection(
              "Facility Location",
              Icons.location_on_outlined,
              [
                _buildNativeInput(
                  "City / District",
                  cityController,
                  Icons.map_outlined,
                ),
                _buildNativeInput(
                  "Full Address",
                  addressController,
                  Icons.near_me_rounded,
                  maxLines: 2,
                ),
                _buildNativeInput(
                  "Lead Administrator",
                  adminNameController,
                  Icons.person_pin_rounded,
                ),
              ],
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
            color: Colors.black.withValues(alpha: 0.015),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.redAccent, size: 20),
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
                  dropdownColor: Colors.white,
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
}
