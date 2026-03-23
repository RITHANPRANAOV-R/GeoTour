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
          if (!mounted) return;
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

  Widget _buildRoleCard(String role, IconData icon, String description) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF8F9FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 28),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome to GeoTour!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please select your role to get started.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRoleCard(
                      "tourist",
                      Icons.explore_rounded,
                      "Explore securely with real-time alerts",
                    ),
                    _buildRoleCard(
                      "police",
                      Icons.local_police_rounded,
                      "Monitor and respond to emergencies",
                    ),
                    _buildRoleCard(
                      "hospital",
                      Icons.local_hospital_rounded,
                      "Manage medical requests and info",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading || selectedRole == null ? null : handleRoleSelection,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Continue"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
