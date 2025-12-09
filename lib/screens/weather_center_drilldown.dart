import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherCenterDrillDownScreen extends StatelessWidget {
  final Map<String, dynamic> row;

  const WeatherCenterDrillDownScreen({
    super.key,
    required this.row,
  });

  // ---------- small helpers -------------------------------------------------

  num _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _asInt(dynamic v) => _asNum(v).toInt();

  String _formatInt(num v) => NumberFormat('#,###').format(v);

  String _formatMph(num v) => '${v.toStringAsFixed(1)} mph';

  double _probabilityPercent() {
    // normalized field (0–1) or already-percent field
    final dynP = row['probability'] ??
        row['Probability'] ??
        row['prob'] ??
        row['Wind Outage Probability %'];

    final p = _asNum(dynP);
    if (p == 0) return 0;

    // If backend gave 0–1, turn into percent; if > 1, assume already %
    return p <= 1.0 ? (p * 100.0) : p.toDouble();
  }

  int _expectedCustomersOut() {
    final dyn = row['customersOut'] ??
        row['Customers Out'] ??
        row['Predicted Customers Out'] ??
        row['predicted_customers_out'] ??
        row['expected_customers_out'] ??
        row['expectedCustomersOut'];

    return _asInt(dyn);
  }

  int _population() {
    final dyn = row['population'] ?? row['Population'];
    return _asInt(dyn);
  }

  String _severityLabel() {
    final dyn = row['severity'] ??
        row['Severity'] ??
        row['threat_level'] ??
        row['Threat Level'] ??
        '0';
    final sevInt = _asInt(dyn).clamp(0, 3);
    return sevInt.toString();
  }

  @override
  Widget build(BuildContext context) {
    // County / state from either normalized or raw keys
    final county = (row['county'] ?? row['County'] ?? '').toString();
    final state = (row['state'] ?? row['State'] ?? '').toString();

    final expectedGust = _asNum(
      row['expectedGust'] ??
          row['Expected Gust'] ??
          row['gust'] ??
          row['Gust'],
    );

    final expectedSustained = _asNum(
      row['expectedSustained'] ??
          row['Expected Sustained'] ??
          row['sustained'] ??
          row['Sustained'],
    );

    final maxGust = _asNum(
      row['maxGust'] ??
          row['Max Gust'] ??
          row['peak_gust'] ??
          row['Peak Gust'] ??
          expectedGust,
    );

    final maxSustained = _asNum(
      row['maxSustained'] ??
          row['Max Sustained'] ??
          row['max_sustained'] ??
          expectedSustained,
    );

    final crews = _asInt(
      row['crews'] ??
          row['Crews'] ??
          row['crewRecommendation'] ??
          row['Crew Recommendation'],
    );

    final lvl = _severityLabel();
    final probPct = _probabilityPercent();
    final custOut = _expectedCustomersOut();
    final pop = _population();

    final popText = _formatInt(pop);
    final custText = custOut > 0 ? _formatInt(custOut) : '--';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: Text('$county, $state'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Threat Level', lvl, Colors.orange),
          _tile('Expected Gust', _formatMph(expectedGust)),
          _tile('Expected Sustained', _formatMph(expectedSustained)),
          _tile('Max Gust', _formatMph(maxGust)),
          _tile('Max Sustained', _formatMph(maxSustained)),
          _tile('Probability', '${probPct.toStringAsFixed(0)}%'),
          _tile('Crew Recommendation', crews.toString()),
          _buildMetricCard('Expected Customers Out', custText),
          _tile('Population', popText),
          const SizedBox(height: 20),
          const Text(
            "This is a detailed view for the selected county's wind analysis, "
                "outage likelihood, and threat level.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value, [Color? color]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? Colors.grey).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMetricCard(String label, String value) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: const Color(0xFF141414),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBBBBBB),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFF6A00),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
