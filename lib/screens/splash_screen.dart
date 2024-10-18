
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telex/generated/assets.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}
class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // Add a small delay for the splash screen
    await Future.delayed(const Duration(seconds: 1));
    // Check if user is logged in

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If logged in, navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // If not logged in, navigate to sigIn screen
      Navigator.pushReplacementNamed(context, '/sigIn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(
      child: Image.asset(
          Assets.imgF2),),
    );
  }
}