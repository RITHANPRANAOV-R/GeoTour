import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

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

  Future<void> handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password")),
      );
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
        _navigateToProfileSetup(selectedRole);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup failed")),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Attempt to sign in and check role compatibility
        User? user = await AuthService().signInWithEmailPassword(email, password);
        if (user != null) {
          final userData = await UserService().getUserMainDoc(user.uid);
          final existingRoles = userData?["roles"] as List<dynamic>? ?? [];
          
          if (existingRoles.contains("police") && selectedRole == "tourist") {
            await UserService().createUserMainDoc(
              uid: user.uid,
              email: email,
              role: selectedRole,
            );
            _navigateToProfileSetup(selectedRole);
          } else {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("This account already exists and does not support additional roles.")),
            );
          }
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email already in use. Please sign in or use a different password.")),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
      Navigator.pushReplacementNamed(context, "/googleInitialRoleSelection");
      return;
    }

    // Existing user: check if they are Police and can add Tourist
    final existingRoles = userData["roles"] as List<dynamic>? ?? [];
    
    if (existingRoles.contains("police") && !existingRoles.contains("tourist")) {
      // If Police, we can still send them to the selection screen but we should handle it there 
      // OR specifically ask if they want to add the Tourist role.
      // For now, let's send them to the selection screen to pick Tourist if they want.
      setState(() => isLoading = false);
      Navigator.pushReplacementNamed(context, "/googleInitialRoleSelection");
    } else {
      // Regular login flow
      if (existingRoles.length > 1) {
        setState(() => isLoading = false);
        Navigator.pushReplacementNamed(context, "/postAuthRoleSelection");
      } else {
        final role = userData["activeRole"] ?? existingRoles.first;
        final roleCompletion = userData["roleCompletion"] as Map<String, dynamic>? ?? {};
        final isCompleted = roleCompletion[role] ?? false;

        if (isCompleted) {
          _navigateToHome(role);
        } else {
          _navigateToProfileSetup(role);
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
        Navigator.pushReplacementNamed(context, "/policeHome");
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
                      "Create Account",
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

                    DropdownButtonFormField(
                      value: selectedRole,
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
                      decoration: InputDecoration(
                        labelText: "Select Role",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                        onPressed: isLoading ? null : handleSignUp,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Sign Up",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
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
                        onPressed: isLoading ? null : handleGoogleSignUp,
                        child: const Text(
                          "Continue with Google",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, "/signIn");
                          },
                          child: const Text(
                            "Sign In",
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
