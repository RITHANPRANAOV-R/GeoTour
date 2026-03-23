import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'get_started_screen.dart';
import 'splash_screen.dart';
import '../tourist/dashboard_screen.dart';
import '../police/police_dashboard.dart';
import '../hospital/hospital_home.dart';
import '../admin/admin_home.dart';

import '../tourist/tourist_profile_setup.dart';
import '../police/police_profile_setup.dart';
import '../hospital/hospital_profile_setup.dart';
import '../admin/admin_profile_setup.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final User? user = snapshot.data;
        if (user == null) {
          return const GetStartedScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: AuthService().getUserProfileStream(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const GetStartedScreen();
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final roles = userData["roles"] as List<dynamic>? ?? [];
            if (roles.isEmpty) return const GetStartedScreen();

            final role = userData["activeRole"] ?? roles.first;
            final roleCompletion =
                userData["roleCompletion"] as Map<String, dynamic>? ?? {};
            final isCompleted = roleCompletion[role] ?? false;

            if (isCompleted) {
              switch (role) {
                case "tourist":
                  return const DashboardScreen();
                case "police":
                  return const PoliceDashboard();
                case "medical":
                case "hospital":
                  return const HospitalHomeScreen();
                case "admin":
                  return const AdminHomeScreen();
                default:
                  return const GetStartedScreen();
              }
            } else {
              switch (role) {
                case "tourist":
                  return const TouristProfileSetupScreen();
                case "police":
                  return const PoliceProfileSetupScreen();
                case "medical":
                case "hospital":
                  return const HospitalProfileSetupScreen();
                case "admin":
                  return const AdminProfileSetupScreen();
                default:
                  return const GetStartedScreen();
              }
            }
          },
        );
      },
    );
  }
}
