import 'package:flutter/material.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/risk_widget.dart';
import '../widgets/map_widget.dart';

class ProNukeDash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/pronukedash.png',
              fit: BoxFit.cover,
            ),
          ),

          // ======== GAUGE BOX (TOP LEFT) ========
          Positioned(
            left: 120,
            top: 520,
            child: SizedBox(
              width: 530,
              height: 320,
              child: GaugeWidget(),
            ),
          ),

          // ======== RISK BAR (TOP RIGHT) ========
          Positioned(
            left: 820,
            top: 560,
            child: SizedBox(
              width: 450,
              height: 120,
              child: RiskWidget(),
            ),
          ),

          // ======== RADAR MAP (CENTER) ========
          Positioned(
            left: 420,
            top: 900,
            child: SizedBox(
              width: 600,
              height: 400,
              child: MapWidget(),
            ),
          ),

          // ======== BOTTOM BUTTONS ========
          Positioned(
            left: 600,
            top: 1500,
            child: SizedBox(
              width: 350,
              height: 120,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 24, color: Colors.orange),
                  SizedBox(width: 12),
                  Text("SYSTEM READY", style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
