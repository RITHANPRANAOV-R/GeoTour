import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/tourist_login_screen.dart';
import 'screens/auth/police_login_screen.dart';
import 'screens/auth/medical_login_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/tourist/tourist_profile_setup.dart';
import 'screens/dummy/tourist_home.dart';
import 'screens/auth_new/get_started_screen.dart';
import 'screens/auth_new/sign_in_screen.dart';
import 'screens/auth_new/sign_up_screen.dart';




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
      title: 'GeoTour',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() async {
  await FirebaseFirestore.instance.collection("test").add({
    "name": "rithan",
    "time": DateTime.now().toString(),
  });

  setState(() {
    _counter++;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
