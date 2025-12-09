import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopUnderConstruction extends StatelessWidget {
  const ShopUnderConstruction({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 720;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Supply Hub'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'UTILITY SUPPLY',
                style: GoogleFonts.robotoMono(
                  fontSize: isNarrow ? 14 : 16,
                  letterSpacing: 4,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'STORE WIRING IN PROGRESS',
                textAlign: TextAlign.center,
                style: GoogleFonts.wallpoet(
                  fontSize: isNarrow ? 26 : 34,
                  letterSpacing: 3,
                  color: const Color(0xFFFF6A00),
                  shadows: const [
                    Shadow(
                      color: Color(0xFFFFA040),
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: Color(0xFFFF6A00),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We’re building a proper high-voltage supply experience.\n'
                'IBEW-built tools, PPE, conduit, and storm-truck kits\n'
                'are being wired into this portal.',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: isNarrow ? 11 : 13,
                  height: 1.6,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatusLights(),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatusLights() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statusDot(Colors.red, 'OFFLINE'),
        const SizedBox(width: 16),
        _statusDot(Colors.orange, 'WIRING'),
        const SizedBox(width: 16),
        _statusDot(Colors.green, 'COMING ONLINE'),
      ],
    );
  }

  static Widget _statusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.7),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
