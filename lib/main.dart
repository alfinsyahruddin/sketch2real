import 'package:flutter/material.dart';
import 'package:sketch2real/pages/splashscreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketch2Real',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        accentColor: Colors.yellow,
      ),
      home: MySplashScreen(),
    );
  }
}
