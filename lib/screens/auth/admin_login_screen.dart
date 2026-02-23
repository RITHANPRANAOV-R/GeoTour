import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  Future<void> handleAdminLogin(BuildContext context) async {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    User? user = await authService.signInWithGoogle();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login cancelled")),
      );
      return;
    }

    final uid = user.uid;

    bool exists = await firestoreService.checkUserExists("admins", uid);

    if (!exists) {
      await firestoreService.createUserDoc(
        collection: "admins",
        uid: uid,
        data: {
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "role": "admin",
          "createdAt": DateTime.now().toIso8601String(),
        },
      );
    }

    Navigator.pushReplacementNamed(context, "/adminDashboard");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Admin Login"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Admin Panel 🧑‍💻",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Login strictly using Google account",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => handleAdminLogin(context),
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
