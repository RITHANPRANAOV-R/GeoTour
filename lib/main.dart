import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth_new/get_started_screen.dart';
import 'screens/auth_new/sign_in_screen.dart';
import 'screens/auth_new/sign_up_screen.dart';

import 'screens/tourist/tourist_profile_setup.dart';
import 'screens/dummy/tourist_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

/*************  ✨ Windsurf Command ⭐  *************/
/// The main entry point for the application. This initializes the
/// Flutter binding and the Firebase app, then runs the application.
/*******  2b2858f3-d1c8-4a8b-864d-5e9e2ec417a4  *******/class MyApp extends StatelessWidget {
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
        "/touristHome": (context) => const TouristHomeScreen(),
      },
    );
  }
}
