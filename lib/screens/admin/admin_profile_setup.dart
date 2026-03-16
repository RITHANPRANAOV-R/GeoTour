import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';

class AdminProfileSetupScreen extends StatefulWidget {
  const AdminProfileSetupScreen({super.key});

  @override
  State<AdminProfileSetupScreen> createState() => _AdminProfileSetupScreenState();
}

class _AdminProfileSetupScreenState extends State<AdminProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController adminCodeController = TextEditingController();
  bool isLoading = false;

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty || adminCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("admins").doc(user.uid).set({
        "name": nameController.text.trim(),
        "adminCode": adminCodeController.text.trim(),
        "profileCompleted": true,
      });
      await UserService().updateProfileCompleted(user.uid, true, "admin");
      Navigator.pushReplacementNamed(context, "/adminHome");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Profile Setup")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: adminCodeController, decoration: const InputDecoration(labelText: "Admin Code")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : saveProfile,
              child: isLoading ? const CircularProgressIndicator() : const Text("Complete Setup"),
            ),
          ],
        ),
      ),
    );
  }
}
