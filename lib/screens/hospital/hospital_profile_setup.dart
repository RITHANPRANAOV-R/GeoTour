import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';

class HospitalProfileSetupScreen extends StatefulWidget {
  const HospitalProfileSetupScreen({super.key});

  @override
  State<HospitalProfileSetupScreen> createState() =>
      _HospitalProfileSetupScreenState();
}

class _HospitalProfileSetupScreenState
    extends State<HospitalProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController hospitalIdController = TextEditingController();
  final TextEditingController hospitalNameController = TextEditingController();
  bool isLoading = false;

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty ||
        hospitalIdController.text.isEmpty ||
        hospitalNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("hospitals")
          .doc(user.uid)
          .set({
            "name": nameController.text.trim(),
            "hospitalId": hospitalIdController.text.trim(),
            "hospitalName": hospitalNameController.text.trim(),
            "profileCompleted": true,
          });
      await UserService().updateProfileCompleted(user.uid, true, "hospital");
      Navigator.pushReplacementNamed(context, "/hospitalHome");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospital Profile Setup")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: hospitalIdController,
              decoration: const InputDecoration(labelText: "Staff ID"),
            ),
            TextField(
              controller: hospitalNameController,
              decoration: const InputDecoration(labelText: "Hospital Name"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : saveProfile,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Complete Setup"),
            ),
          ],
        ),
      ),
    );
  }
}
