// import 'package:flutter/material.dart';
// import 'package:login_signup/components/sign_in_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//         debugShowCheckedModeBanner: false,
//         home: LoginPage(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:telex/screens/auth/sign_in_screen.dart'; // Import Firebase Core


void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Initialize Firebase asynchronously
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize Firebase and wait for completion
      future: initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Once Firebase is initialized, return MaterialApp
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SignInScreen(),
          );
        } else {
          // Show loading indicator while Firebase is initializing
          return CircularProgressIndicator();
        }
      },
    );
  }
}
