import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
// Navigation is handled by named routes in main.dart, so logic in screens remains valid as long as route names didn't change.
// However, I will check if any manual imports need updating.
import '../../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleEmailLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    User? user = await AuthService().signInWithEmailPassword(email, password);

    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid login")),
      );
      return;
    }

    final userData = await UserService().getUserMainDoc(user.uid);

    if (userData == null) {
      setState(() => isLoading = false);
      Navigator.pushReplacementNamed(context, "/signUp");
      return;
    }

    final roles = userData["roles"] as List<dynamic>? ?? [];

    if (roles.length > 1) {
      setState(() => isLoading = false);
      Navigator.pushReplacementNamed(context, "/postAuthRoleSelection");
    } else {
      final role = userData["activeRole"] ?? roles.first;
      final roleCompletion = userData["roleCompletion"] as Map<String, dynamic>? ?? {};
      final isCompleted = roleCompletion[role] ?? false;
      _navigateBasedOnRoleAndCompletion(role, isCompleted);
    }
  }

  Future<void> handleGoogleLogin() async {
    setState(() => isLoading = true);

    User? user = await AuthService().signInWithGoogle();

    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google login cancelled")),
      );
      return;
    }

    final userData = await UserService().getUserMainDoc(user.uid);

    if (userData == null) {
      setState(() => isLoading = false);
      Navigator.pushReplacementNamed(context, "/googleInitialRoleSelection");
      return;
    }

    final roles = userData["roles"] as List<dynamic>? ?? [];

    if (roles.length > 1) {
      setState(() => isLoading = false);
      Navigator.pushReplacementNamed(context, "/postAuthRoleSelection");
    } else {
      final role = userData["activeRole"] ?? roles.first;
      final roleCompletion = userData["roleCompletion"] as Map<String, dynamic>? ?? {};
      final isCompleted = roleCompletion[role] ?? false;
      _navigateBasedOnRoleAndCompletion(role, isCompleted);
    }
  }

  void _navigateBasedOnRoleAndCompletion(String role, bool completed) {
    setState(() => isLoading = false);
    if (completed) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "GeoTour",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "AI-powered tourist safety with\nreal-time geo-intelligence",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Sign In",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : handleEmailLogin,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : handleGoogleLogin,
                        child: const Text(
                          "Sign in with Google",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Not yet registered? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/signUp");
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
