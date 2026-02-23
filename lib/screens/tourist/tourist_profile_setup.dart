import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/user_service.dart';

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
  final TextEditingController emergencyPhoneController = TextEditingController();

  String gender = "Male";
  bool termsAccepted = false;

  bool isLoading = false;

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
    if (usernameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        dobController.text.isEmpty ||
        locationController.text.isEmpty ||
        emergencyNameController.text.isEmpty ||
        emergencyRelationController.text.isEmpty ||
        emergencyPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details")),
      );
      return;
    }

    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Conditions")),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final uid = user.uid;

    try {
      await FirebaseFirestore.instance.collection("tourists").doc(uid).set({
        "uid": uid,
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

      await UserService().updateProfileCompleted(uid, true);

      setState(() => isLoading = false);

      Navigator.pushReplacementNamed(context, "/touristHome");
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving details: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
              _inputField("Phone number", phoneController),
              _inputField("Date of birth", dobController),
              _inputField("Location", locationController),
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
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("Male"),
                  Radio(
                    value: "Female",
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("Female"),
                  Radio(
                    value: "Other",
                    groupValue: gender,
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
              _inputField("Phone number", emergencyPhoneController),
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

  Widget _inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
