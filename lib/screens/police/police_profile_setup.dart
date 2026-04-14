import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../widgets/premium_toast.dart';

class PoliceProfileSetupScreen extends StatefulWidget {
  const PoliceProfileSetupScreen({super.key});

  @override
  State<PoliceProfileSetupScreen> createState() =>
      _PoliceProfileSetupScreenState();
}

class _PoliceProfileSetupScreenState extends State<PoliceProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController badgeController = TextEditingController();
  final TextEditingController rankController = TextEditingController();
  final TextEditingController stationController = TextEditingController();
  final TextEditingController divisionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController stationAddressController =
      TextEditingController();
  final TextEditingController stationPhoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    badgeController.dispose();
    rankController.dispose();
    stationController.dispose();
    divisionController.dispose();
    phoneController.dispose();
    stationAddressController.dispose();
    stationPhoneController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty ||
        badgeController.text.isEmpty ||
        stationController.text.isEmpty ||
        phoneController.text.isEmpty) {
      PremiumToast.show(
        context,
        title: "Officer Validation",
        message:
            "Please fill essential fields: Name, Badge, Station, and Phone.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("police")
            .doc(user.uid)
            .set({
              "uid": user.uid,
              "name": nameController.text.trim(),
              "badgeNumber": badgeController.text.trim(),
              "rank": rankController.text.trim(),
              "station": stationController.text.trim(),
              "division": divisionController.text.trim(),
              "personalPhone": phoneController.text.trim(),
              "stationAddress": stationAddressController.text.trim(),
              "stationPhone": stationPhoneController.text.trim(),
              "profileCompleted": true,
              "updatedAt": DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));

        await UserService().updateProfileCompleted(user.uid, true, "police");

        if (mounted) {
          Navigator.pushReplacementNamed(context, "/policeDashboardChoice");
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Registration Error",
            message: "Unable to save profile details: $e",
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
                "Geotour Police",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                "Setup your officer profile to start responding",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
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
                      "Officer Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      "Full Name *",
                      nameController,
                      Icons.person_outline,
                    ),
                    _buildField(
                      "Badge / Batch Number *",
                      badgeController,
                      Icons.badge_outlined,
                    ),
                    _buildField(
                      "Rank / Designation",
                      rankController,
                      Icons.military_tech_outlined,
                    ),
                    _buildField(
                      "Personal Phone Number *",
                      phoneController,
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const Divider(height: 40),
                    const Text(
                      "Station Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      "Police Station Name *",
                      stationController,
                      Icons.location_city_outlined,
                    ),
                    _buildField(
                      "Division / District",
                      divisionController,
                      Icons.map_outlined,
                    ),
                    _buildField(
                      "Station Landline",
                      stationPhoneController,
                      Icons.local_phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      "Station Full Address",
                      stationAddressController,
                      Icons.location_on_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
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
                                "Complete Registration",
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
            borderSide: const BorderSide(color: Colors.blue, width: 1),
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
