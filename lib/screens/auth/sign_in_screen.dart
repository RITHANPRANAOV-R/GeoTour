import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
// Navigation is handled by named routes in main.dart, so logic in screens remains valid as long as route names didn't change.
// However, I will check if any manual imports need updating.
import '../../services/user_service.dart';
import '../../widgets/google_logo.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid login")),
        );
      }
      return;
    }

    final userData = await UserService().getUserMainDoc(user.uid);

    if (userData == null) {
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/signUp");
      }
      return;
    }

    final roles = userData["roles"] as List<dynamic>? ?? [];

    if (roles.length > 1) {
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/postAuthRoleSelection");
      }
    } else {
      final role = userData["activeRole"] ?? roles.first;
      final roleCompletion = userData["roleCompletion"] as Map<String, dynamic>? ?? {};
      final isCompleted = roleCompletion[role] ?? false;
      if (mounted) {
        _navigateBasedOnRoleAndCompletion(role, isCompleted);
      }
    }
  }

  Future<void> handleGoogleLogin() async {
    setState(() => isLoading = true);

    User? user = await AuthService().signInWithGoogle();

    if (user == null) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google login cancelled")),
        );
      }
      return;
    }

    final userData = await UserService().getUserMainDoc(user.uid);

    if (userData == null) {
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/googleInitialRoleSelection");
      }
      return;
    }

    final roles = userData["roles"] as List<dynamic>? ?? [];

    if (roles.length > 1) {
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/postAuthRoleSelection");
      }
    } else {
      final role = userData["activeRole"] ?? roles.first;
      final roleCompletion = userData["roleCompletion"] as Map<String, dynamic>? ?? {};
      final isCompleted = roleCompletion[role] ?? false;
      if (mounted) {
        _navigateBasedOnRoleAndCompletion(role, isCompleted);
      }
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
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Text(
                "GeoTour",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "AI-powered tourist safety with\nreal-time geo-intelligence",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFAFAFA)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F1F1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/adminLogin");
                          },
                          child: const Text(
                            "Login as Admin",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : handleEmailLogin,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Sign In"),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : handleGoogleLogin,
                      icon: const GoogleLogoWidget(height: 24),
                      label: const Text("Continue with Google"),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Not yet registered? ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/signUp");
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
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
