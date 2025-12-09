import 'package:flutter/material.dart';

class WeatherCenterResults extends StatefulWidget {
  const WeatherCenterResults({
    super.key,
    required this.rows,
    this.showDetails = true,
  });

  final List<Map<String, dynamic>> rows;
  final bool showDetails;

  @override
  State<WeatherCenterResults> createState() => _WeatherCenterResultsState();
}

class _WeatherCenterResultsState extends State<WeatherCenterResults> {
  static const _kBg = Color(0xFF0E0E0E);
  static const _kPanel = Color(0xFF141414);
  static const _kOrange = Color(0xFFFF6A00);

  String _selectedThreatFilter = 'All';

  // ------------ helpers so we can handle both raw + normalized rows ----------

  num _numField(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final v = row[k];
      if (v == null) continue;
      if (v is num) return v;
      final parsed = num.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _stringField(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final v = row[k];
      if (v == null) continue;
      return v.toString();
    }
    return fallback;
  }

  // ---------- threat level (front‑end only, driven by severity first) --------

  String _levelOf(Map<String, dynamic> row) {
    // severity 0–3 (normalized)
    final int severity = _numField(row, <String>[
      'severity',
      'Severity',
      'threat_level',
      'threatLevel',
      'maxSeverity',
      'max_severity',
    ]).toInt();

    if (severity > 0) {
      // keep it directly in sync with "Threat Level: 2" etc.
      return 'Level $severity';
    }

    // fallback: derive from probability / customers if severity is missing

    // probability as percent, handle 0–1 or 0–100
    double prob = _numField(row, <String>[
      'Wind Outage Probability %',
      'Probability',
      'probability',
      'prob',
      'probability_pct',
      'probability_percent',
      'probabilityPercent',
    ]).toDouble();
    if (prob > 0 && prob <= 1) {
      prob = prob * 100.0;
    }

    final int customers = _numField(row, <String>[
      'Expected Customers Out',
      'Predicted Customers Out',
      'expected_customers_out',
      'expectedCustomersOut',
      'predicted_customers_out',
      'customersOut',
      'customers_out',
    ]).toInt();

    if (prob >= 45 || customers >= 25000) return 'Level 3';
    if (prob >= 20 || customers >= 5000) return 'Level 2';
    if (prob >= 12 || customers > 0) return 'Level 1';
    return 'Level 0';
  }

  List<Map<String, dynamic>> get filteredRows {
    if (_selectedThreatFilter == 'All') {
      return widget.rows;
    }

    return widget.rows.where((row) {
      final level = _levelOf(row);
      return level == _selectedThreatFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.rows.length;
    final visible = filteredRows.length;

    // ignore: avoid_print
    print('RESULTS SCREEN total rows=$total visible=$visible');

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Results',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.rows.isEmpty
            ? const Center(
                child: Text(
                  'No results returned from backend.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Threat filter row ----
                  Row(
                    children: [
                      const Text(
                        'Threat:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _kPanel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kOrange, width: 1),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedThreatFilter,
                          dropdownColor: _kPanel,
                          underline: const SizedBox(),
                          iconEnabledColor: _kOrange,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'All',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Level 1',
                              child: Text(
                                'Level 1',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Level 2',
                              child: Text(
                                'Level 2',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Level 3',
                              child: Text(
                                'Level 3',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedThreatFilter = value;
                            });
                          },
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$visible of $total results',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ---- List of county cards ----
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible,
                      itemBuilder: (context, index) {
                        final row = filteredRows[index];

                        final county = _stringField(
                          row,
                          <String>['County', 'county', 'county_name'],
                          fallback: 'Unknown',
                        );
                        final state = _stringField(
                          row,
                          <String>['State', 'state', 'state_name'],
                          fallback: '',
                        );

                        final level = _levelOf(row);

                        // probability display
                        double prob = _numField(row, <String>[
                          'Wind Outage Probability %',
                          'Probability',
                          'probability',
                          'prob',
                          'probability_pct',
                          'probability_percent',
                          'probabilityPercent',
                        ]).toDouble();
                        if (prob > 0 && prob <= 1) {
                          prob = prob * 100.0;
                        }
                        final String probText =
                            prob == 0 ? 'N/A' : prob.toStringAsFixed(0);

                        // expected customers out (any variant)
                        final int expectedCust = _numField(row, <String>[
                          'Expected Customers Out',
                          'Predicted Customers Out',
                          'expected_customers_out',
                          'expectedCustomersOut',
                          'predicted_customers_out',
                          'customersOut',
                          'customers_out',
                        ]).toInt();
                        final String customersText =
                            expectedCust == 0 ? 'N/A' : expectedCust.toString();

                        final cluster = _stringField(
                          row,
                          <String>['Cluster', 'cluster'],
                          fallback: '',
                        );
                        final threatDate = _stringField(
                          row,
                          <String>[
                            'Predicted Impact Date',
                            'impact_date',
                            'impactDate',
                          ],
                          fallback: '',
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _kPanel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _kOrange.withOpacity(0.6),
                              width: 0.8,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              '$county, $state',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Threat: $level   |   Cluster: $cluster\n'
                                'Wind outage prob: $probText %\n'
                                'Expected customers out: $customersText\n'
                                'Peak impact: $threatDate',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: _kOrange,
                            ),
                            onTap: () {
                              // hook drill‑down here later if you want.
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
