import 'package:flutter/material.dart';

class DAWoodButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;

  const DAWoodButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    const img = AssetImage('assets/images/button_sparks.png');
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320, minHeight: 64),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image: img,
            fit: BoxFit.cover,
            colorFilter: primary ? null : const ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 12)),
            BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
          ],
          border: Border.all(color: Colors.orangeAccent.withOpacity(.35), width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: .6,
                      shadows: [ Shadow(blurRadius: 8, color: Colors.black, offset: Offset(0, 2)) ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
