import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';

class PoliceProfileSetupScreen extends StatefulWidget {
  const PoliceProfileSetupScreen({super.key});

  @override
  State<PoliceProfileSetupScreen> createState() => _PoliceProfileSetupScreenState();
}

class _PoliceProfileSetupScreenState extends State<PoliceProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController badgeController = TextEditingController();
  final TextEditingController stationController = TextEditingController();
  bool isLoading = false;

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty || badgeController.text.isEmpty || stationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("police").doc(user.uid).set({
        "name": nameController.text.trim(),
        "badgeNumber": badgeController.text.trim(),
        "station": stationController.text.trim(),
        "profileCompleted": true,
      });
      await UserService().updateProfileCompleted(user.uid, true, "police");
      Navigator.pushReplacementNamed(context, "/policeDashboardChoice");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Police Profile Setup")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: badgeController, decoration: const InputDecoration(labelText: "Badge Number")),
            TextField(controller: stationController, decoration: const InputDecoration(labelText: "Police Station")),
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
