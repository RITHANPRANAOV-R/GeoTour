import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../screens/tourist/profile_screen.dart';
import '../screens/police/police_profile_screen.dart';
import '../screens/hospital/hospital_profile_screen.dart';
import 'logout_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Drawer(
      backgroundColor: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: AuthService().getUserProfileStream(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading profile"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            String name = "Guest";
            String email = user?.email ?? "No email";
            String activeRole = "Member";
            String roleKey = 'tourist';

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['name'] ?? data['displayName'] ?? "User";
              activeRole = data['activeRole'] ?? "Member";
              roleKey = data['activeRole']?.toString().toLowerCase() ?? 'tourist';
            }

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          activeRole.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 24, endIndent: 24),
                
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.person_outline_rounded,
                        title: "My Profile",
                        onTap: () {
                          Navigator.pop(context);
                          Widget target;
                          if (roleKey == 'police') {
                            target = const PoliceProfileScreen();
                          } else if (roleKey == 'hospital') {
                            target = const HospitalProfileScreen();
                          } else {
                            target = const TouristProfileScreen();
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (context) => target));
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.info_outline_rounded,
                        title: "About Us",
                        onTap: () {
                          Navigator.pop(context);
                          // Future: About Us logic
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.contact_support_outlined,
                        title: "Contact Us",
                        onTap: () {
                          Navigator.pop(context);
                          // Future: Contact Us logic
                        },
                      ),
                    ],
                  ),
                ),

                // Footer
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: "Logout",
                  color: Colors.redAccent,
                  onTap: () {
                    LogoutDialog.show(context);
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      onTap: onTap,
    );
  }
}
