import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class PostAuthRoleSelectionScreen extends StatelessWidget {
  const PostAuthRoleSelectionScreen({super.key});

  Widget _buildRoleCard(
    BuildContext context,
    String role,
    Map<String, dynamic> roleCompletion,
  ) {
    IconData icon;
    String description;
    switch (role.toLowerCase()) {
      case "tourist":
        icon = Icons.explore_rounded;
        description = "Explore securely with real-time alerts";
        break;
      case "police":
        icon = Icons.local_police_rounded;
        description = "Monitor and respond to emergencies";
        break;
      case "hospital":
      case "medical":
        icon = Icons.local_hospital_rounded;
        description = "Manage medical requests and info";
        break;
      case "admin":
        icon = Icons.admin_panel_settings_rounded;
        description = "System administration panel";
        break;
      default:
        icon = Icons.person_rounded;
        description = "Access your profile";
    }

    return GestureDetector(
      onTap: () => _navigateByRole(context, role, roleCompletion),
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
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
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: UserService().getUserMainDoc(user?.uid ?? ""),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            final roles = snapshot.data?["roles"] as List<dynamic>? ?? [];
            final roleCompletion =
                snapshot.data?["roleCompletion"] as Map<String, dynamic>? ?? {};

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Select Role",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Which role would you like to use?",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: roles
                          .map(
                            (role) => _buildRoleCard(
                              context,
                              role.toString(),
                              roleCompletion,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateByRole(
    BuildContext context,
    String role,
    Map<String, dynamic> roleCompletion,
  ) {
    final bool isCompleted = roleCompletion[role] ?? false;

    if (isCompleted) {
      switch (role) {
        case "tourist":
          Navigator.pushReplacementNamed(context, "/touristHome");
          break;
        case "police":
          Navigator.pushReplacementNamed(context, "/policeHome");
          break;
        case "medical":
        case "hospital":
          Navigator.pushReplacementNamed(context, "/hospitalHome");
          break;
        case "admin":
          Navigator.pushReplacementNamed(context, "/adminHome");
          break;
      }
    } else {
      switch (role) {
        case "tourist":
          Navigator.pushReplacementNamed(context, "/touristProfileSetup");
          break;
        case "police":
          Navigator.pushReplacementNamed(context, "/policeProfileSetup");
          break;
        case "medical":
        case "hospital":
          Navigator.pushReplacementNamed(context, "/hospitalProfileSetup");
          break;
        case "admin":
          Navigator.pushReplacementNamed(context, "/adminProfileSetup");
          break;
      }
    }
  }
}
