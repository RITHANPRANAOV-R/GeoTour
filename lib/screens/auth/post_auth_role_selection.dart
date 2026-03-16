import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class PostAuthRoleSelectionScreen extends StatelessWidget {
  const PostAuthRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: UserService().getUserMainDoc(user?.uid ?? ""),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final roles = snapshot.data?["roles"] as List<dynamic>? ?? [];
            final roleCompletion =
                snapshot.data?["roleCompletion"] as Map<String, dynamic>? ?? {};

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Role",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Which role would you like to use?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  ...roles.map(
                    (role) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(role.toString().toUpperCase()),
                        onTap: () {
                          _navigateByRole(
                            context,
                            role.toString(),
                            roleCompletion,
                          );
                        },
                      ),
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
          Navigator.pushReplacementNamed(context, "/policeDashboardChoice");
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
