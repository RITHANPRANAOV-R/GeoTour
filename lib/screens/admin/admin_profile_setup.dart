import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../widgets/premium_toast.dart';

class AdminProfileSetupScreen extends StatefulWidget {
  const AdminProfileSetupScreen({super.key});

  @override
  State<AdminProfileSetupScreen> createState() =>
      _AdminProfileSetupScreenState();
}

class _AdminProfileSetupScreenState extends State<AdminProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController adminCodeController = TextEditingController();
  bool isLoading = false;
  List<String> _userRoles = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load roles
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userRoles = List<String>.from(userData['roles'] ?? []);
        });
      }

      // Load existing admin data
      final adminDoc = await FirebaseFirestore.instance
          .collection("admins")
          .doc(user.uid)
          .get();
      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? "";
          adminCodeController.text = data['adminCode'] ?? "";
        });
      }
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    adminCodeController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final code = adminCodeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      PremiumToast.show(
        context,
        title: "Incomplete Setup",
        message: "Please fill all administrative profile fields.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("admins")
            .doc(user.uid)
            .set({
              "uid": user.uid,
              "name": name,
              "adminCode": code,
              "profileCompleted": true,
              "updatedAt": DateTime.now().toIso8601String(),
            });
        await UserService().updateProfileCompleted(user.uid, true, "admin");
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/adminHome");
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Security Exception",
            message: "Unable to initialize admin profile: $e",
            type: ToastType.error,
          );
        }
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "GeoTour",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Administration Unit Setup",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                "Complete your profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildField(
                "Full Name",
                nameController,
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildField(
                "Admin Authorization Code",
                adminCodeController,
                Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : saveProfile,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Save Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Account Roles Section
              if (_userRoles.length > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Switch Identity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._userRoles.where((r) => r != 'admin').map((role) {
                      IconData roleIcon = Icons.person_rounded;
                      String roleName = role;
                      if (role == 'tourist') {
                        roleIcon = Icons.explore_rounded;
                        roleName = "Tourist Explorer";
                      } else if (role == 'police') {
                        roleIcon = Icons.local_police_rounded;
                        roleName = "Police Responder";
                      } else if (role == 'hospital' || role == 'medical') {
                        roleIcon = Icons.local_hospital_rounded;
                        roleName = "Medical Staff";
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Icon(roleIcon, color: Colors.black),
                          title: Text(
                            "Switch to $roleName",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              setState(() => isLoading = true);
                              await UserService().switchRole(user.uid, role);
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (route) => false,
                                );
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.black54),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
