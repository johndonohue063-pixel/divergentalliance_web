import 'package:flutter/material.dart';
import 'castle_landing.dart';

class LogoSplashScreen extends StatefulWidget {
  const LogoSplashScreen({super.key});

  @override
  State<LogoSplashScreen> createState() => _LogoSplashScreenState();
}

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, // full black, no white
      body: Center(
        child: CircleAvatar(
          radius: 80,
          backgroundColor: Colors.black, // circle blends into the background
          backgroundImage: AssetImage('assets/icons/app_icon.png'),
        ),
      ),
    );
  }
}
