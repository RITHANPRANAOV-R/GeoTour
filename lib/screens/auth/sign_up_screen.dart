import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/google_logo.dart';
import '../../widgets/premium_toast.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String selectedRole = "tourist";
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        PremiumToast.show(
          context,
          title: "Missing Info",
          message: "Please enter both an email and a password.",
          type: ToastType.warning,
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = await AuthService().signUpWithEmailPassword(email, password);

      if (user != null) {
        await UserService().createUserMainDoc(
          uid: user.uid,
          email: email,
          role: selectedRole,
        );
        if (mounted) {
          _navigateToProfileSetup(selectedRole);
        }
      } else {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Signup Error",
            message: "We couldn't create your account. Please try again.",
            type: ToastType.error,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          // Attempt to sign in and check role compatibility
          User? user = await AuthService().signInWithEmailPassword(
            email,
            password,
          );
          if (user != null) {
            final userData = await UserService().getUserMainDoc(user.uid);
            final existingRoles = userData?["roles"] as List<dynamic>? ?? [];

            if (existingRoles.contains("police") && selectedRole == "tourist") {
              await UserService().createUserMainDoc(
                uid: user.uid,
                email: email,
                role: selectedRole,
              );
              if (mounted) {
                _navigateToProfileSetup(selectedRole);
              }
            } else {
              setState(() => isLoading = false);
              if (mounted) {
                PremiumToast.show(
                  context,
                  title: "Account Conflict",
                  message:
                      "This account already exists and doesn't support the selected role.",
                  type: ToastType.warning,
                );
              }
            }
          }
        } on FirebaseAuthException catch (authError) {
          setState(() => isLoading = false);
          if (mounted) {
            String message = "Authentication failed.";
            if (authError.code == 'invalid-credential' ||
                authError.code == 'wrong-password') {
              message = "Incorrect password for this account.";
            } else {
              message = authError.message ?? message;
            }
            PremiumToast.show(
              context,
              title: "Login Failed",
              message: message,
              type: ToastType.error,
            );
          }
        }
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Auth Exception",
            message: e.message ?? "An authentication error occurred.",
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        PremiumToast.show(
          context,
          title: "System Error",
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> handleGoogleSignUp() async {
    setState(() => isLoading = true);

    User? user = await AuthService().signInWithGoogle();

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final userData = await UserService().getUserMainDoc(user.uid);

    if (userData == null) {
      setState(() => isLoading = false);
      // New user: must select a role
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/googleInitialRoleSelection");
      }
      return;
    }

    // Existing user: check if they are Police and can add Tourist
    final existingRoles = userData["roles"] as List<dynamic>? ?? [];

    if (existingRoles.contains("police") &&
        !existingRoles.contains("tourist")) {
      // If Police, we can still send them to the selection screen but we should handle it there
      // OR specifically ask if they want to add the Tourist role.
      // For now, let's send them to the selection screen to pick Tourist if they want.
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/googleInitialRoleSelection");
      }
    } else {
      // Regular login flow
      if (existingRoles.length > 1) {
        setState(() => isLoading = false);
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/postAuthRoleSelection");
        }
      } else {
        final role = userData["activeRole"] ?? existingRoles.first;
        final roleCompletion =
            userData["roleCompletion"] as Map<String, dynamic>? ?? {};
        final isCompleted = roleCompletion[role] ?? false;

        if (mounted) {
          if (isCompleted) {
            _navigateToHome(role);
          } else {
            _navigateToProfileSetup(role);
          }
        }
      }
    }

    setState(() => isLoading = false);
  }

  void _navigateToProfileSetup(String role) {
    switch (role) {
      case "tourist":
        Navigator.pushReplacementNamed(context, "/touristProfileSetup");
        break;
      case "police":
        Navigator.pushReplacementNamed(context, "/policeProfileSetup");
        break;
      case "medical": // Fallback if medical is used instead of hospital
      case "hospital":
        Navigator.pushReplacementNamed(context, "/hospitalProfileSetup");
        break;
      case "admin":
        Navigator.pushReplacementNamed(context, "/adminProfileSetup");
        break;
    }
  }

  void _navigateToHome(String role) {
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFAFAFA)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFF1F1F1),
                    width: 1.5,
                  ),
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
                      "Create Account",
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
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      initialValue: selectedRole,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: const [
                        DropdownMenuItem(
                          value: "tourist",
                          child: Text("Tourist"),
                        ),
                        DropdownMenuItem(
                          value: "police",
                          child: Text("Police"),
                        ),
                        DropdownMenuItem(
                          value: "hospital",
                          child: Text("Hospital"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value.toString();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Select Role",
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading ? null : handleSignUp,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Sign Up"),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : handleGoogleSignUp,
                      icon: const GoogleLogoWidget(height: 24),
                      label: const Text("Continue with Google"),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, "/signIn");
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
