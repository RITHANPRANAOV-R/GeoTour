import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                "GeoTour",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Select your role to continue",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 50),

              _roleButton(
                context,
                title: "Tourist",
                icon: Icons.travel_explore,
                onTap: () {
                  Navigator.pushNamed(context, "/touristLogin");
                },
              ),

              const SizedBox(height: 20),

              _roleButton(
                context,
                title: "Police",
                icon: Icons.local_police,
                onTap: () {
                  Navigator.pushNamed(context, "/policeLogin");
                },
              ),

              const SizedBox(height: 20),

              _roleButton(
                context,
                title: "Medical",
                icon: Icons.local_hospital,
                onTap: () {
                  Navigator.pushNamed(context, "/medicalLogin");
                },
              ),

              const SizedBox(height: 20),

              _roleButton(
                context,
                title: "Admin",
                icon: Icons.admin_panel_settings,
                onTap: () {
                  Navigator.pushNamed(context, "/adminLogin");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }
}
