import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../services/user_service.dart';
import '../tourist/location_picker_screen.dart';
import '../../widgets/premium_toast.dart';

class HospitalProfileSetupScreen extends StatefulWidget {
  const HospitalProfileSetupScreen({super.key});

  @override
  State<HospitalProfileSetupScreen> createState() =>
      _HospitalProfileSetupScreenState();
}

class _HospitalProfileSetupScreenState
    extends State<HospitalProfileSetupScreen> {
  final TextEditingController hospitalNameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController erPhoneController = TextEditingController();
  final TextEditingController ambulanceNoController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String category = "General / Multi-Specialty";
  bool isLoading = false;
  LatLng? _selectedLocation;

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
  void dispose() {
    hospitalNameController.dispose();
    licenseController.dispose();
    erPhoneController.dispose();
    ambulanceNoController.dispose();
    addressController.dispose();
    cityController.dispose();
    adminNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LocationPickerScreen(title: "Pick Hospital Location"),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedLocation = result['point'];
        addressController.text = result['name'];
        // Try to extract city if it looks like a standard address, or just leave as is
      });
    }
  }

  Future<void> saveProfile() async {
    if (hospitalNameController.text.isEmpty ||
        licenseController.text.isEmpty ||
        erPhoneController.text.isEmpty ||
        addressController.text.isEmpty) {
      PremiumToast.show(
        context,
        title: "Facility Validation",
        message:
            "Please fill in essential fields: Name, License, ER Number, and Address.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("hospitals")
            .doc(user.uid)
            .set({
              "uid": user.uid,
              "hospitalName": hospitalNameController.text.trim(),
              "licenseNumber": licenseController.text.trim(),
              "category": category,
              "emergencyPhone": erPhoneController.text.trim(),
              "ambulanceNumber": ambulanceNoController.text.trim(),
              "fullAddress": addressController.text.trim(),
              "city": cityController.text.trim(),
              "adminName": adminNameController.text.trim(),
              "officialEmail": emailController.text.trim(),
              "latitude": _selectedLocation?.latitude,
              "longitude": _selectedLocation?.longitude,
              "location": _selectedLocation != null
                  ? GeoPoint(
                      _selectedLocation!.latitude,
                      _selectedLocation!.longitude,
                    )
                  : null,
              "profileCompleted": true,
              "updatedAt": DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));

        await UserService().updateProfileCompleted(user.uid, true, "hospital");

        if (mounted) {
          Navigator.pushReplacementNamed(context, "/hospitalHome");
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Registration Error",
            message: "Unable to save facility details: $e",
            type: ToastType.error,
          );
        }
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "GeoTour Medical",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.redAccent,
                ),
              ),
              const Text(
                "Setup your facility profile to support tourist health safety",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Facility Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      "Hospital Name *",
                      hospitalNameController,
                      Icons.local_hospital_outlined,
                    ),
                    _buildField(
                      "Registration / License No *",
                      licenseController,
                      Icons.verified_user_outlined,
                    ),

                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Hospital Type",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => category = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(height: 40),
                    const Text(
                      "Emergency Contacts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      "Emergency ER Phone *",
                      erPhoneController,
                      Icons.emergency_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      "Ambulance Number",
                      ambulanceNoController,
                      Icons.medical_services_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      "Official Email",
                      emailController,
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const Divider(height: 40),
                    const Text(
                      "Location & Admin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      "City / Town",
                      cityController,
                      Icons.map_outlined,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            "Hospital Full Address *",
                            addressController,
                            Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: IconButton.filled(
                            onPressed: _pickLocation,
                            icon: const Icon(Icons.map_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildField(
                      "Admin / Contact Person Name",
                      adminNameController,
                      Icons.person_add_disabled_outlined,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Register Facility",
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

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
