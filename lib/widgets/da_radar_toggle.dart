import 'package:flutter/material.dart';
import '../ui/da_brand.dart';

enum RadarMode { map, tactical }

class DaRadarToggle extends StatelessWidget {
  final RadarMode mode;
  final ValueChanged<RadarMode> onModeChanged;

  const DaRadarToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTactical = mode == RadarMode.tactical;

    return GestureDetector(
      onTap: () {
        onModeChanged(isTactical ? RadarMode.map : RadarMode.tactical);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF101010),
          boxShadow: [
            BoxShadow(
              color: DABrand.orange.withOpacity(0.7),
              blurRadius: 18,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: DABrand.orange.withOpacity(0.9),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MAP',
              style: TextStyle(
                fontSize: 12,
                color: isTactical ? Colors.grey : DABrand.orange,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 36,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
                border: Border.all(color: Colors.grey.shade700, width: 1),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    left: isTactical ? 16 : 2,
                    top: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DABrand.orange,
                        boxShadow: [
                          BoxShadow(
                            color: DABrand.orange.withOpacity(0.9),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TACTICAL',
              style: TextStyle(
                fontSize: 12,
                color: isTactical ? DABrand.orange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
