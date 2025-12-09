import 'package:flutter/material.dart';
import '../theme/da_nuclear_theme.dart';

class DaNeonGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;

  const DaNeonGauge({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final int percentage = (value * 100).round().clamp(0, 100);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DaNuclearTheme.accentSoft.withOpacity(0.8),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            startAngle: 0.0,
            endAngle: 6.28318530718,
            colors: <Color>[
              Color(0xFF252525),
              Color(0xFFFFD470),
              Color(0xFFFFA500),
              Color(0xFF252525),
            ],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF050505),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: DaNuclearTheme.accentSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
