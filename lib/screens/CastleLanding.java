package screens;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/da_brand.dart';
import 'weather_center_pro.dart';
import 'wx_pin_gate.dart';

class CastleLanding extends StatelessWidget {
  const CastleLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen hero background
          Positioned.fill(
            child: Image.asset(
              'assets/images/truck.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay to enhance readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Divergent Alliance',
                    style: GoogleFonts.oswald(
                      fontSize: 34,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: DABrand.orange,
                      shadows: [
                        Shadow(
                          color: DABrand.orange.withOpacity(0.9),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Storm ready command console',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),

                  const Spacer(),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LandingButton(
                            label: 'Default',
                            primary: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WeatherCenterProScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _LandingButton(
                            label: 'Gateway PIN',
                            primary: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WxPinGateScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

class _LandingButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _LandingButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: primary ? 22 : 6,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            color: primary ? DABrand.orange : Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: primary
                ? null
                : Border.all(color: DABrand.orange, width: 1.3),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: DABrand.orange.withOpacity(0.8),
                      blurRadius: 24,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.robotoCondensed(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primary ? Colors.black : Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}
