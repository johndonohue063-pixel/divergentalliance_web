import 'package:flutter/material.dart';

class DaNuclearTheme {
  DaNuclearTheme._();

  static const Color backgroundDark = Color(0xFF000000);
  static const Color panelDark = Color(0xFF0E0E0E);
  static const Color accentNeon = Color(0xFFFFA500);
  static const Color accentSoft = Color(0xFFFFC25E);
  static const Color backgroundDark87 = Color(0xDD000000);

  static BoxDecoration get backgroundDecoration {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topCenter,
        radius: 1.4,
        colors: <Color>[
          Color(0xFF0A0A0A),
          Color(0xFF000000),
        ],
      ),
    );
  }

  static BoxDecoration get panelDecoration {
    return BoxDecoration(
      color: panelDark,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFF1F1F1F),
        width: 1.2,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: accentNeon.withOpacity(0.15),
          blurRadius: 25,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static ButtonStyle get primaryActionButton {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF191919),
      elevation: 18,
      shadowColor: accentNeon.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: accentNeon,
          width: 1.4,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 22),
    );
  }
}
