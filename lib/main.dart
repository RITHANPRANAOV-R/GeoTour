import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth/get_started_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/tourist/tourist_profile_setup.dart';
import 'screens/auth/post_auth_role_selection.dart';
import 'screens/auth/google_initial_role_selection.dart';
import 'screens/police/police_profile_setup.dart';
import 'screens/hospital/hospital_profile_setup.dart';
import 'screens/admin/admin_profile_setup.dart';
import 'screens/tourist/tourist_home.dart';
import 'screens/police/police_home.dart';
import 'screens/hospital/hospital_home.dart';
import 'screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GetStartedScreen(),
      routes: {
        "/getStarted": (context) => const GetStartedScreen(),
        "/signIn": (context) => const SignInScreen(),
        "/signUp": (context) => const SignUpScreen(),
        "/touristProfileSetup": (context) => const TouristProfileSetupScreen(),
        "/policeProfileSetup": (context) => const PoliceProfileSetupScreen(),
        "/hospitalProfileSetup": (context) =>
            const HospitalProfileSetupScreen(),
        "/adminProfileSetup": (context) => const AdminProfileSetupScreen(),
        "/touristHome": (context) => const TouristHomeScreen(),
        "/policeHome": (context) => const PoliceHomeScreen(),
        "/hospitalHome": (context) => const HospitalHomeScreen(),
        "/adminHome": (context) => const AdminHomeScreen(),
        "/postAuthRoleSelection": (context) =>
            const PostAuthRoleSelectionScreen(),
        "/googleInitialRoleSelection": (context) =>
            const GoogleInitialRoleSelectionScreen(),
      },
    );
  }
}
