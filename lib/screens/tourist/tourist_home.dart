import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class TouristHomeScreen extends StatelessWidget {
  const TouristHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tourist Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/signIn",
                (route) => false,
              );
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          "Tourist Home Screen ✅",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
