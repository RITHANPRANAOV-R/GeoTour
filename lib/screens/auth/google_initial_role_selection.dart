import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class GoogleInitialRoleSelectionScreen extends StatefulWidget {
  const GoogleInitialRoleSelectionScreen({super.key});

  @override
  State<GoogleInitialRoleSelectionScreen> createState() =>
      _GoogleInitialRoleSelectionScreenState();
}

class _GoogleInitialRoleSelectionScreenState
    extends State<GoogleInitialRoleSelectionScreen> {
  String? selectedRole;
  bool isLoading = false;

  final List<String> roles = ["tourist", "police", "hospital"];

  Future<void> handleRoleSelection() async {
    if (selectedRole == null) return;

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userData = await UserService().getUserMainDoc(user.uid);
      final existingRoles = userData?["roles"] as List<dynamic>? ?? [];

      // Enforce the special rule: only Police can add Tourist
      if (userData != null && !existingRoles.contains(selectedRole)) {
        if (existingRoles.contains("police") && selectedRole == "tourist") {
          await UserService().createUserMainDoc(
            uid: user.uid,
            email: user.email ?? "",
            role: selectedRole!,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Additional roles are restricted for this account.")),
          );
          setState(() => isLoading = false);
          return;
        }
      } else if (userData == null) {
        // Completely new user
        await UserService().createUserMainDoc(
          uid: user.uid,
          email: user.email ?? "",
          role: selectedRole!,
        );
      }

      _navigateToProfileSetup(selectedRole!);
    }
    setState(() => isLoading = false);
  }

  void _navigateToProfileSetup(String role) {
    switch (role) {
      case "tourist":
        Navigator.pushReplacementNamed(context, "/touristProfileSetup");
        break;
      case "police":
        Navigator.pushReplacementNamed(context, "/policeProfileSetup");
        break;
      case "hospital":
        Navigator.pushReplacementNamed(context, "/hospitalProfileSetup");
        break;
      case "admin":
        Navigator.pushReplacementNamed(context, "/adminProfileSetup");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to GeoTour!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("Please select your role to get started."),
            const SizedBox(height: 30),
            DropdownButton<String>(
              value: selectedRole,
              hint: const Text("Select Role"),
              isExpanded: true,
              items: roles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedRole = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleRoleSelection,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
