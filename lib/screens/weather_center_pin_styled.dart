import 'package:flutter/material.dart';

class WeatherCenterPinStyled extends StatefulWidget {
  const WeatherCenterPinStyled({super.key});

  @override
  State<WeatherCenterPinStyled> createState() => _WeatherCenterPinStyledState();
}

class _WeatherCenterPinStyledState extends State<WeatherCenterPinStyled>
    with SingleTickerProviderStateMixin {
  static const _kOrange = Color(0xFFFF6A00);

  late final AnimationController _glowController;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/weather_center_door.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.45),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 72),
                  child: AnimatedBuilder(
                    animation: _glow,
                    builder: (context, child) {
                      final glowStrength = 6 + 10 * _glow.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _kOrange, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange.withOpacity(0.7),
                              blurRadius: glowStrength,
                              spreadRadius: 1.5 + _glow.value * 2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const _PinDisplay(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDisplay extends StatelessWidget {
  const _PinDisplay();

  static const _kOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'ENTER ACCESS PIN',
          style: TextStyle(
            color: _kOrange,
            fontSize: 16,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _PinDot(),
            SizedBox(width: 8),
            _PinDot(),
            SizedBox(width: 8),
            _PinDot(),
            SizedBox(width: 8),
            _PinDot(),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Weather Center • Secure Gate',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot();

  static const _kOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kOrange, width: 1.5),
      ),
    );
  }
}
