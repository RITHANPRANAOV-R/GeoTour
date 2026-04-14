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
import 'screens/police/police_dashboard.dart';
import 'screens/tourist/dashboard_screen.dart';
import 'screens/tourist/medical_info_setup_screen.dart';
import 'screens/hospital/hospital_dashboard.dart';
import 'screens/admin/admin_home.dart';
import 'screens/police/police_dashboard_choice.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        cardTheme: CardThemeData(
          // Changed CardTheme to CardThemeData
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black12, width: 1.5),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black87,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: const AuthWrapper(),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
          ),
          child: child!,
        );
      },
      routes: {
        "/getStarted": (context) => const GetStartedScreen(),
        "/signIn": (context) => const SignInScreen(),
        "/signUp": (context) => const SignUpScreen(),
        "/touristProfileSetup": (context) => const TouristProfileSetupScreen(),
        "/policeProfileSetup": (context) => const PoliceProfileSetupScreen(),
        "/hospitalProfileSetup": (context) =>
            const HospitalProfileSetupScreen(),
        "/adminProfileSetup": (context) => const AdminProfileSetupScreen(),
        "/policeHome": (context) => const PoliceDashboard(),
        "/hospitalHome": (context) => const HospitalDashboard(),
        "/adminHome": (context) => const AdminHomeScreen(),
        "/postAuthRoleSelection": (context) =>
            const PostAuthRoleSelectionScreen(),
        "/googleInitialRoleSelection": (context) =>
            const GoogleInitialRoleSelectionScreen(),
        "/medicalInfoSetup": (context) => const MedicalInfoSetupScreen(),
        "/adminLogin": (context) => const AdminLoginScreen(),
        "/touristHome": (context) => const DashboardScreen(),
        "/policeDashboardChoice": (context) =>
            const PoliceDashboardChoiceScreen(),
      },
    );
  }
}
