import 'package:flutter/material.dart';
import 'package:divergent_alliance/services/wx_backend_service.dart';
import 'package:divergent_alliance/screens/weather_center_drilldown.dart';

class WeatherResults extends StatefulWidget {
  final bool isNational;
  final String state;
  final String region;
  final int hoursOut;

  const WeatherResults({
    super.key,
    required this.isNational,
    required this.state,
    required this.region,
    required this.hoursOut,
  });

  @override
  State<WeatherResults> createState() => _WeatherResultsState();
}

class _WeatherResultsState extends State<WeatherResults> {
  static const _kBg = Color(0xFF0E0E0E);
  static const _kPanel = Color(0xFF141414);
  static const _kOrange = Color(0xFFFF6A00);

  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  int? _threatFilter = null; // All = null
  int _visible = 6;

  // Region mapping (one primary region per state)
  static const Map<String, String> _stateToRegion = {
    // Northeast
    'Maine': 'Northeast',
    'New Hampshire': 'Northeast',
    'Vermont': 'Northeast',
    'Massachusetts': 'Northeast',
    'Rhode Island': 'Northeast',
    'Connecticut': 'Northeast',
    'New York': 'Northeast',
    'New Jersey': 'Northeast',
    'Pennsylvania': 'Northeast',

    // Mid-Atlantic
    'Maryland': 'Mid-Atlantic',
    'Delaware': 'Mid-Atlantic',
    'Virginia': 'Mid-Atlantic',
    'West Virginia': 'Mid-Atlantic',
    'District of Columbia': 'Mid-Atlantic',

    // Southeast
    'Florida': 'Southeast',
    'Georgia': 'Southeast',
    'Alabama': 'Southeast',
    'South Carolina': 'Southeast',
    'North Carolina': 'Southeast',
    'Mississippi': 'Southeast',

    // Central
    'Tennessee': 'Central',
    'Kentucky': 'Central',
    'Arkansas': 'Central',

    // South Central
    'Texas': 'South Central',
    'Louisiana': 'South Central',
    'Oklahoma': 'South Central',

    // Midwest
    'Ohio': 'Midwest',
    'Michigan': 'Midwest',
    'Indiana': 'Midwest',
    'Illinois': 'Midwest',
    'Wisconsin': 'Midwest',
    'Minnesota': 'Midwest',
    'Iowa': 'Midwest',
    'Missouri': 'Midwest',
    'North Dakota': 'Midwest',
    'South Dakota': 'Midwest',
    'Nebraska': 'Midwest',
    'Kansas': 'Midwest',

    // Northwest
    'Washington': 'Northwest',
    'Oregon': 'Northwest',
    'Idaho': 'Northwest',
    'Montana': 'Northwest',
    'Wyoming': 'Northwest',

    // Southwest
    'California': 'Southwest',
    'Nevada': 'Southwest',
    'Utah': 'Southwest',
    'Arizona': 'Southwest',
    'New Mexico': 'Southwest',
    'Colorado': 'Southwest',
  };

  bool get _isRegionLevel => widget.isNational;
  bool get _isStateLevel => !widget.isNational && widget.region.isNotEmpty;
  bool get _isCountyLevel =>
      !widget.isNational && widget.region.isEmpty && widget.state.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (mounted) {
        setState(() => loading = true);
      }

      List<Map<String, dynamic>> data = [];

      // PRIMARY QUERY
      if (widget.isNational) {
        data = await WxBackendService.fetchNationwide(
          hours: widget.hoursOut,
        );
      } else if (widget.region.isNotEmpty) {
        // Region first
        data = await WxBackendService.fetchRegion(
          region: widget.region,
          hours: widget.hoursOut,
        );

        // FALLBACK: if region comes back empty, try mapped region from state, then nationwide
        if (data.isEmpty && widget.state.isNotEmpty) {
          final String? mappedRegion = _stateToRegion[widget.state];
          if (mappedRegion != null && mappedRegion.isNotEmpty) {
            final byStateRegion = await WxBackendService.fetchRegion(
              region: mappedRegion,
              hours: widget.hoursOut,
            );
            if (byStateRegion.isNotEmpty) {
              data = byStateRegion;
            }
          }
        }

        if (data.isEmpty) {
          final nationwide = await WxBackendService.fetchNationwide(
            hours: widget.hoursOut,
          );
          if (nationwide.isNotEmpty) {
            data = nationwide;
          }
        }
      } else if (widget.state.isNotEmpty) {
        // State first
        data = await WxBackendService.fetchState(
          state: widget.state,
          hours: widget.hoursOut,
        );

        // FALLBACK: if state comes back empty, try its region, then nationwide
        if (data.isEmpty) {
          final String? mappedRegion = _stateToRegion[widget.state];
          if (mappedRegion != null && mappedRegion.isNotEmpty) {
            final byRegion = await WxBackendService.fetchRegion(
              region: mappedRegion,
              hours: widget.hoursOut,
            );
            if (byRegion.isNotEmpty) {
              data = byRegion;
            }
          }
        }

        if (data.isEmpty) {
          final nationwide = await WxBackendService.fetchNationwide(
            hours: widget.hoursOut,
          );
          if (nationwide.isNotEmpty) {
            data = nationwide;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        rows = data;
        loading = false;
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
  int _levelOf(Map<String, dynamic> r) {
    return int.tryParse(r["severity"].toString()) ?? 0;
  }

  double _numField(Map<String, dynamic> r, String key) {
    final v = r[key];
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  List<Map<String, dynamic>> get noZeroRows {
    return rows;
  }




  List<Map<String, dynamic>> get filteredRows {
    final list = noZeroRows;
    if (_threatFilter == null) return list;
    return list.where((r) => _levelOf(r) == _threatFilter).toList();
  }

  List<Map<String, dynamic>> get pagedCountyRows {
    final list = filteredRows;
    final count = list.length < _visible ? list.length : _visible;
    return list.sublist(0, count);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isNational
        ? "Nationwide Forecast"
        : (widget.region.isNotEmpty
            ? "Region: ${widget.region}"
            : "State: ${widget.state}");

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/runreportclickscreen.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.05),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: _kOrange,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildThreatFilter(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredRows.isEmpty
                        ? const Center(
                            child: Text(
                              "No results match your filter.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(child: _buildList()),
                              if (_isCountyLevel &&
                                  _visible < filteredRows.length)
                                _buildNextButton(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThreatFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOrange.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Threat Filter:",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          _filterButton("All", null),
          _filterButton("1", 1),
          _filterButton("2", 2),
          _filterButton("3", 3),
        ],
      ),
    );
  }

  Widget _filterButton(String label, int? value) {
    final selected = _threatFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _visible = 12;
          _threatFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _kOrange : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isRegionLevel) {
      return _buildRegionList();
    } else if (_isStateLevel) {
      return _buildStateList();
    } else {
      return _buildCountyList();
    }
  }

  // REGION LEVEL (Nationwide)
  Widget _buildRegionList() {
    final Map<String, List<Map<String, dynamic>>> byRegion = {};

    for (final r in filteredRows) {
      final state = (r['state'] ?? '').toString();
      final region = _stateToRegion[state] ?? 'Other';
      byRegion.putIfAbsent(region, () => []).add(r);
    }

    final regions = byRegion.keys.where((r) => r != 'Other').toList()..sort();

    return ListView.builder(
      itemCount: regions.length,
      itemBuilder: (context, index) {
        final region = regions[index];
        final items = byRegion[region] ?? [];

        int maxLevel = 0;
        double maxGust = 0;
        for (final r in items) {
          final lvl = _levelOf(r);
          if (lvl > maxLevel) maxLevel = lvl;
          final g = _numField(r, 'maxGust');
          if (g > maxGust) maxGust = g;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeatherResults(
                  isNational: false,
                  state: "",
                  region: region,
                  hoursOut: widget.hoursOut,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kOrange.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  region,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Max Threat Level: $maxLevel",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Worst Max Gust: ${maxGust.toStringAsFixed(0)} mph",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Counties: ${items.length}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // STATE LEVEL (within a Region)
  Widget _buildStateList() {
    final Map<String, List<Map<String, dynamic>>> byState = {};

    for (final r in filteredRows) {
      final state = (r['state'] ?? '').toString();
      byState.putIfAbsent(state, () => []).add(r);
    }

    final states = byState.keys.toList()..sort();

    return ListView.builder(
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        final items = byState[state] ?? [];

        int maxLevel = 0;
        double maxGust = 0;
        for (final r in items) {
          final lvl = _levelOf(r);
          if (lvl > maxLevel) maxLevel = lvl;
          final g = _numField(r, 'maxGust');
          if (g > maxGust) maxGust = g;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeatherResults(
                  isNational: false,
                  state: state,
                  region: "",
                  hoursOut: widget.hoursOut,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kOrange.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Max Threat Level: $maxLevel",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Worst Max Gust: ${maxGust.toStringAsFixed(0)} mph",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Counties: ${items.length}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // COUNTY LEVEL (within a State)
  Widget _buildCountyList() {
    final list = pagedCountyRows;

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final lvl = _levelOf(r);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeatherCenterDrillDownScreen(row: r),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kOrange.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${r['county']}, ${r['state']}",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Threat Level: $lvl",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Expected Gust: ${r['expectedGust']} mph",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Expected Sustained: ${r['expectedSustained']} mph",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Max Gust: ${r['maxGust']} mph",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Probability: ${(r['probability'] * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Crew Recommendation: ${r['crews']}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Pagination button (county level only)
  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kOrange,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          setState(() {
            _visible += 20;
          });
        },
        child: const Text(
          "Next",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
