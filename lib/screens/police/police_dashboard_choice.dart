import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class PoliceDashboardChoiceScreen extends StatelessWidget {
  const PoliceDashboardChoiceScreen({super.key});

  Future<void> _handleTouristTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userData = await UserService().getUserMainDoc(user.uid);
    final roleCompletion =
        userData?["roleCompletion"] as Map<String, dynamic>? ?? {};
    final roles = userData?["roles"] as List<dynamic>? ?? [];

    // If tourist role doesn't exist yet OR profile is not completed, go to setup
    final bool hasTouristRole = roles.contains("tourist");
    final bool touristCompleted = roleCompletion["tourist"] ?? false;

    if (!context.mounted) return;

    if (!hasTouristRole || !touristCompleted) {
      Navigator.pushReplacementNamed(context, "/touristProfileSetup");
    } else {
      Navigator.pushReplacementNamed(context, "/touristHome");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome,\nOfficer",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select a dashboard to proceed. You can switch between them later from the profile settings.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              _buildChoiceCard(
                context,
                title: "Police Dashboard",
                subtitle:
                    "Access emergency alerts, patrol assignments, and incident reports.",
                icon: Icons.local_police_rounded,
                onTap: () =>
                    Navigator.pushReplacementNamed(context, "/policeHome"),
                isPrimary: true,
              ),

              const SizedBox(height: 20),

              _buildChoiceCard(
                context,
                title: "Tourist Dashboard",
                subtitle:
                    "View geo-fence zones, safety tips, and travel intelligence.",
                icon: Icons.explore_rounded,
                onTap: () => _handleTouristTap(context),
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isPrimary
              ? null
              : Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isPrimary ? 0.1 : 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.black,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isPrimary ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPrimary ? Colors.white70 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
