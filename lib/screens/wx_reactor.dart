import "package:flutter/material.dart";

/// Full-screen high-tech orange/black background used by WeatherCenterPro.
/// Pure visual; ignores pointer events so it never blocks taps.
class WxReactor extends StatelessWidget {
  const WxReactor({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base reactor wallpaper
          Image.asset(
            "assets/images/wx_reactor_wall.png",
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),

          // Dark vertical vignette to keep content readable
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0x99000000),
                  Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Top orange glow spill
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x55FF6A00),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Central reactor ring + glow
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x44FF6A00),
                  width: 1.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66FF6A00),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
