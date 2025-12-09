import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "We're still wiring this page. Thanks for your patience. Please check back soon.",
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Color(0xFFFF6A00), fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
