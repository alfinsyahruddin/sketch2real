import 'package:flutter/material.dart';
import 'package:sketch2real/pages/home/home.dart';
import 'package:splashscreen/splashscreen.dart';

class MySplashScreen extends StatefulWidget {
  @override
  _MySplashScreenState createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      seconds: 2,
      navigateAfterSeconds: Home(),
      title: Text(
        'Sketch2Real',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
          color: const Color(0xFFFBFF48),
        ),
      ),
      image: Image.asset('assets/icon.png'),
      backgroundColor: const Color(0xFFFF99A5),
      photoSize: 50,
      loaderColor: Colors.white,
    );
  }
}
