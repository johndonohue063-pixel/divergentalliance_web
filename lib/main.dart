import 'package:flutter/material.dart';
import 'ui/neon_landing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DivergentAllianceApp());
}

class DivergentAllianceApp extends StatelessWidget {
  const DivergentAllianceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divergent Alliance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6A00),
          secondary: Color(0xFFFFB000),
        ),
        textTheme: Typography.whiteCupertino.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const NeonLandingScreen(),
    );
  }
}
