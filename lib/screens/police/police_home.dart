import 'package:flutter/material.dart';

class PoliceHomeScreen extends StatelessWidget {
  const PoliceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Police Dashboard"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_police, size: 100, color: Colors.blue.shade900),
            const SizedBox(height: 20),
            const Text(
              "Welcome, Officer!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Real-time geo-intelligence at your service."),
          ],
        ),
      ),
    );
  }
}
