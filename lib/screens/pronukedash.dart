import 'package:flutter/material.dart';

class ProNukeDash extends StatelessWidget {
  const ProNukeDash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background
          Positioned.fill(
            child: Image.asset(
              'assets/pronukedash.png',
              fit: BoxFit.cover,
            ),
          ),

          // === TOP LEFT BOX (for your main gauge cluster) ===
          Positioned(
            left: 120,
            top: 520,
            child: SizedBox(
              width: 530,
              height: 320,
              child: Placeholder(
                strokeWidth: 2,
              ),
            ),
          ),

          // === TOP RIGHT BOX (for current threat / status bar) ===
          Positioned(
            left: 820,
            top: 560,
            child: SizedBox(
              width: 450,
              height: 120,
              child: Placeholder(
                strokeWidth: 2,
              ),
            ),
          ),

          // === CENTER BOX (for CONUS radar map) ===
          Positioned(
            left: 420,
            top: 900,
            child: SizedBox(
              width: 600,
              height: 400,
              child: Placeholder(
                strokeWidth: 2,
              ),
            ),
          ),

          // === BOTTOM BOX (for buttons / ticker) ===
          Positioned(
            left: 400,
            top: 1450,
            child: SizedBox(
              width: 600,
              height: 140,
              child: Placeholder(
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
