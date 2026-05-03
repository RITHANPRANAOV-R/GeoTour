import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'location_picker_screen.dart';

import '../../services/user_service.dart';
import '../../widgets/premium_toast.dart';

class TouristProfileSetupScreen extends StatefulWidget {
  const TouristProfileSetupScreen({super.key});

  @override
  State<TouristProfileSetupScreen> createState() =>
      _TouristProfileSetupScreenState();
}

class _TouristProfileSetupScreenState extends State<TouristProfileSetupScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyRelationController =
      TextEditingController();
  final TextEditingController emergencyPhoneController =
      TextEditingController();

  String gender = "Male";
  bool termsAccepted = false;

  bool isLoading = false;
  String? existingPoliceName;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if user has a police profile - we offer it but don't force it
      final policeDoc = await FirebaseFirestore.instance
          .collection('police')
          .doc(user.uid)
          .get();

      if (policeDoc.exists && mounted) {
        final data = policeDoc.data();
        if (data != null && data['name'] != null) {
          setState(() {
            existingPoliceName = data['name'];
            // Pre-fill only if currently empty
            if (usernameController.text.isEmpty) {
              usernameController.text = data['name'];
            }
          });
        }
      }
    } catch (e) {
      // Silent error
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    locationController.dispose();
    emergencyNameController.dispose();
    emergencyRelationController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> saveTouristDetails() async {
    // Phone validation regex
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

    if (usernameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        dobController.text.isEmpty ||
        locationController.text.isEmpty ||
        emergencyNameController.text.isEmpty ||
        emergencyRelationController.text.isEmpty ||
        emergencyPhoneController.text.isEmpty) {
      PremiumToast.show(
        context,
        title: "Incomplete Form",
        message: "Please fill in all the required profile details.",
        type: ToastType.warning,
      );
      return;
    }

    if (!phoneRegex.hasMatch(phoneController.text.trim())) {
      PremiumToast.show(
        context,
        title: "Invalid Phone",
        message: "Please enter a valid primary phone number.",
        type: ToastType.warning,
      );
      return;
    }

    if (!phoneRegex.hasMatch(emergencyPhoneController.text.trim())) {
      PremiumToast.show(
        context,
        title: "Invalid Contact",
        message: "Please enter a valid emergency phone number.",
        type: ToastType.warning,
      );
      return;
    }

    if (!termsAccepted) {
      PremiumToast.show(
        context,
        title: "Terms Required",
        message: "Please accept the Terms & Conditions to proceed.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      PremiumToast.show(
        context,
        title: "Auth Error",
        message: "User session not found. Please log in again.",
        type: ToastType.error,
      );
      return;
    }

    final uid = user.uid;

    try {
      final touristId = await UserService().generateTouristId(uid);

      await FirebaseFirestore.instance.collection("tourists").doc(uid).set({
        "uid": uid,
        "touristId": touristId,
        "email": user.email ?? "",
        "username": usernameController.text.trim(),
        "phone": phoneController.text.trim(),
        "dob": dobController.text.trim(),
        "location": locationController.text.trim(),
        "gender": gender,
        "emergencyContact": {
          "name": emergencyNameController.text.trim(),
          "relationship": emergencyRelationController.text.trim(),
          "phone": emergencyPhoneController.text.trim(),
        },
        "profileCompleted": true,
        "updatedAt": DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Ensure tourist role exists in roles array and mark profile complete
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "roles": FieldValue.arrayUnion(["tourist"]),
        "activeRole": "tourist",
      }, SetOptions(merge: true));

      await UserService().updateProfileCompleted(uid, true, "tourist");

      if (!mounted) return;
      setState(() => isLoading = false);

      Navigator.pushReplacementNamed(context, "/medicalInfoSetup");
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      PremiumToast.show(
        context,
        title: "Save Failed",
        message: "Error saving profile details: $e",
        type: ToastType.error,
      );
    }
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 230,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime(2000, 1, 1),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (val) {
                  setState(() {
                    dobController.text = DateFormat('yyyy-MM-dd').format(val);
                  });
                },
              ),
            ),
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LocationPickerScreen(title: "Select your address"),
      ),
    );

    if (result != null) {
      setState(() {
        locationController.text = result['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "GeoTour",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "AI-powered tourist safety with real-time geo-intelligence",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              const Text(
                "Setup your profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 20),
              _inputField("Username", usernameController),
              _inputField(
                "Phone number",
                phoneController,
                keyboardType: TextInputType.phone,
              ),
              _inputField(
                "Date of birth",
                dobController,
                readOnly: true,
                onTap: _showDatePicker,
              ),
              _inputField(
                "Location",
                locationController,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.blue),
                  onPressed: _pickLocation,
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Gender",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Row(
                children: [
                  Radio(
                    value: "Male",
                    // ignore: deprecated_member_use
                    groupValue: gender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("Male"),
                  Radio(
                    value: "Female",
                    // ignore: deprecated_member_use
                    groupValue: gender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("Female"),
                  Radio(
                    value: "Other",
                    // ignore: deprecated_member_use
                    groupValue: gender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("Other"),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Emergency Contact",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              _inputField("Name", emergencyNameController),
              _inputField("Relationship", emergencyRelationController),
              _inputField(
                "Phone number",
                emergencyPhoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: termsAccepted,
                    onChanged: (value) {
                      setState(() => termsAccepted = value ?? false);
                    },
                  ),
                  const Text("Terms and conditions"),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : saveTouristDetails,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
