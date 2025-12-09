import 'package:flutter/material.dart';
import 'weather_center.dart'; // original nav target

class WeatherCenterPin extends StatefulWidget {
  const WeatherCenterPin({super.key});

  @override
  State<WeatherCenterPin> createState() => _WeatherCenterPinState();
}

class _WeatherCenterPinState extends State<WeatherCenterPin> {
  static const int _pinLength = 4;
  String _entered = "";

  void _addDigit(String d) {
    if (_entered.length >= _pinLength) return;

    setState(() {
      _entered += d;
    });

    if (_entered.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WeatherCenter()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FULLSCREEN BACKGROUND, SLIGHTLY ZOOMED TO KILL BLACK BANDS
          Positioned.fill(
            child: Transform.scale(
              scale: 1.08, // tweak this up/down if you still see edges
              child: Image.asset(
                'assets/images/vaultdoor.png', // or weather_center_door.png
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // PIN FIELD OVERLAY (crisp, not scaled)
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      // solid black so the baked "0000" in the art
                      // doesn't ghost through and blur your digits
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6A00),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _entered.padRight(_pinLength, '0'),
                      // If you’d rather have blanks before typing:
                      // _entered.padRight(_pinLength, ' '),
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 8,
                        color: Color(0xFFFF6A00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
