import "dart:convert";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "../ui/da_brand.dart";

const String kBackendBaseUrl = "https://da-wx-backend-1.onrender.com";
const int kDefaultHoursAhead = 36;
const int kMaxSamplePerState = 60;

/// (abbr, name) pairs for state dropdown.
const List<MapEntry<String, String>> kStates = <MapEntry<String, String>>[
  MapEntry("AL", "Alabama"),
  MapEntry("AK", "Alaska"),
  MapEntry("AZ", "Arizona"),
  MapEntry("AR", "Arkansas"),
  MapEntry("CA", "California"),
  MapEntry("CO", "Colorado"),
  MapEntry("CT", "Connecticut"),
  MapEntry("DE", "Delaware"),
  MapEntry("DC", "District of Columbia"),
  MapEntry("FL", "Florida"),
  MapEntry("GA", "Georgia"),
  MapEntry("HI", "Hawaii"),
  MapEntry("ID", "Idaho"),
  MapEntry("IL", "Illinois"),
  MapEntry("IN", "Indiana"),
  MapEntry("IA", "Iowa"),
  MapEntry("KS", "Kansas"),
  MapEntry("KY", "Kentucky"),
  MapEntry("LA", "Louisiana"),
  MapEntry("ME", "Maine"),
  MapEntry("MD", "Maryland"),
  MapEntry("MA", "Massachusetts"),
  MapEntry("MI", "Michigan"),
  MapEntry("MN", "Minnesota"),
  MapEntry("MS", "Mississippi"),
  MapEntry("MO", "Missouri"),
  MapEntry("MT", "Montana"),
  MapEntry("NE", "Nebraska"),
  MapEntry("NV", "Nevada"),
  MapEntry("NH", "New Hampshire"),
  MapEntry("NJ", "New Jersey"),
  MapEntry("NM", "New Mexico"),
  MapEntry("NY", "New York"),
  MapEntry("NC", "North Carolina"),
  MapEntry("ND", "North Dakota"),
  MapEntry("OH", "Ohio"),
  MapEntry("OK", "Oklahoma"),
  MapEntry("OR", "Oregon"),
  MapEntry("PA", "Pennsylvania"),
  MapEntry("RI", "Rhode Island"),
  MapEntry("SC", "South Carolina"),
  MapEntry("SD", "South Dakota"),
  MapEntry("TN", "Tennessee"),
  MapEntry("TX", "Texas"),
  MapEntry("UT", "Utah"),
  MapEntry("VT", "Vermont"),
  MapEntry("VA", "Virginia"),
  MapEntry("WA", "Washington"),
  MapEntry("WV", "West Virginia"),
  MapEntry("WI", "Wisconsin"),
  MapEntry("WY", "Wyoming"),
];

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

/// One county row from /api/wx.
class WxCounty {
  final String county;
  final String state;
  final double expectedGust;
  final double expectedSustained;
  final double maxGust;
  final double maxSustained;
  final double probability; // 0..0.95
  final int crews;
  final int severity; // 0..4
  final int confidence; // 0..100
  final int population;
  final int predictedCustomersOut;
  final DateTime? generatedAt;
  final DateTime? upstreamStamp;
  final String source;
  final String windDirection;
  final int threatIndex; // 0..100 Divergent Threat Index
  final bool directionAnomaly;

  WxCounty({
    required this.county,
    required this.state,
    required this.expectedGust,
    required this.expectedSustained,
    required this.maxGust,
    required this.maxSustained,
    required this.probability,
    required this.crews,
    required this.severity,
    required this.confidence,
    required this.population,
    required this.predictedCustomersOut,
    required this.generatedAt,
    required this.upstreamStamp,
    required this.source,
    required this.windDirection,
    required this.threatIndex,
    required this.directionAnomaly,
  });

  factory WxCounty.fromJson(Map<String, dynamic> json) {
    return WxCounty(
      county: (json["county"] ?? "") as String,
      state: (json["state"] ?? "") as String,
      expectedGust: _toDouble(json["expectedGust"]),
      expectedSustained: _toDouble(json["expectedSustained"]),
      maxGust: _toDouble(json["maxGust"]),
      maxSustained: _toDouble(json["maxSustained"]),
      probability: _toDouble(json["probability"]),
      crews: _toInt(json["crews"]),
      severity: _toInt(json["severity"]),
      confidence: _toInt(json["confidence"]),
      population: _toInt(json["population"]),
      predictedCustomersOut: _toInt(json["predicted_customers_out"]),
      generatedAt: _parseDate(json["generatedAt"]),
      upstreamStamp: _parseDate(json["upstreamStamp"]),
      source: (json["source"] ?? "nws") as String,
      windDirection: (json["windDirection"] ?? "UNKNOWN") as String,
      threatIndex: _toInt(json["threatIndex"]),
      directionAnomaly: json["directionAnomaly"] == true,
    );
  }

  double get probabilityPercent => probability * 100.0;

  String get severityLabel {
    switch (severity) {
      case 4:
        return "Extreme";
      case 3:
        return "Widespread";
      case 2:
        return "Scattered";
      case 1:
        return "Localized";
      default:
        return "Normal";
    }
  }

  Color get severityColor {
    switch (severity) {
      case 4:
        return Colors.redAccent;
      case 3:
        return Colors.deepOrangeAccent;
      case 2:
        return Colors.orangeAccent;
      case 1:
        return DABrand.orange;
      default:
        return Colors.greenAccent;
    }
  }

  Color get threatColor {
    if (threatIndex >= 75) return Colors.redAccent;
    if (threatIndex >= 50) return Colors.deepOrangeAccent;
    if (threatIndex >= 25) return Colors.yellowAccent.shade700;
    return Colors.greenAccent;
  }
}

class WeatherCenterPro extends StatefulWidget {
  const WeatherCenterPro({Key? key}) : super(key: key);

  @override
  State<WeatherCenterPro> createState() => _WeatherCenterProState();
}

class _WeatherCenterProState extends State<WeatherCenterPro>
    with TickerProviderStateMixin {
  String? _selectedState;
  int _hours = kDefaultHoursAhead;
  int _threatFilterMin = 0;

  bool _loading = false;
  String? _error;
  List<WxCounty> _rows = <WxCounty>[];

  int _requestCounter = 0;
  int _activeRequestId = 0;

  late final AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  Future<void> _loadForState(String state) async {
    final int myRequestId = ++_requestCounter;

    setState(() {
      _activeRequestId = myRequestId;
      _loading = true;
      _error = null;
      _rows = <WxCounty>[];
    });

    final Uri uri = Uri.parse(
      "$kBackendBaseUrl/api/wx"
      "?state=$state"
      "&hours=$_hours"
      "&sample=$kMaxSamplePerState"
      "&nocache=1",
    );

    try {
      final http.Response resp = await http.get(uri);
      if (!mounted || myRequestId != _activeRequestId) return;

      if (resp.statusCode != 200) {
        throw Exception("HTTP ${resp.statusCode}");
      }

      final List<dynamic> decoded = jsonDecode(resp.body) as List<dynamic>;
      final List<WxCounty> parsed = decoded
          .map((dynamic e) => WxCounty.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _rows = parsed;
      });
    } catch (e) {
      if (!mounted || myRequestId != _activeRequestId) return;
      setState(() {
        _error = "Failed to load data: $e";
        _rows = <WxCounty>[];
      });
    } finally {
      if (!mounted || myRequestId != _activeRequestId) return;
      setState(() {
        _loading = false;
      });
    }
  }

  int get _totalPredictedOut => _rows.fold<int>(
      0, (int acc, WxCounty r) => acc + r.predictedCustomersOut);
  int get _totalCrews =>
      _rows.fold<int>(0, (int acc, WxCounty r) => acc + r.crews);
  int get _elevatedCount => _rows.where((WxCounty r) => r.severity >= 2).length;

  double get _maxGustState {
    if (_rows.isEmpty) return 0.0;
    double m = _rows.first.maxGust;
    for (final WxCounty r in _rows) {
      if (r.maxGust > m) m = r.maxGust;
    }
    return m;
  }

  double get _avgProbability {
    if (_rows.isEmpty) return 0.0;
    double s = 0.0;
    for (final WxCounty r in _rows) {
      s += r.probability;
    }
    return s / _rows.length;
  }

  int get _maxThreatIndex {
    int m = 0;
    for (final WxCounty r in _rows) {
      if (r.threatIndex > m) m = r.threatIndex;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final Widget base = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildControls(),
                const SizedBox(height: 8),
                _buildAnalogCluster(),
                const SizedBox(height: 8),
                _buildRadarCard(),
                const SizedBox(height: 8),
                _buildCountyList(),
              ],
            ),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050509),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        title: const Text(
          "Divergent Weather Center",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            base,
            if (_loading)
              Center(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: AnimatedBuilder(
                    animation: _spinnerController,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.rotate(
                        angle: _spinnerController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      "assets/images/spinninglogo.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Marquee disabled  intentionally removed.
  Widget _buildMarquee() {
    return const SizedBox.shrink();
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF111317), Color(0xFF181B23)],
        ),
        border: Border.all(color: DABrand.orange.withOpacity(0.8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DABrand.orange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: const InputDecoration(
              labelText: "State",
              hintText: "Select State",
              border: OutlineInputBorder(),
            ),
            dropdownColor: const Color(0xFF111317),
            items: kStates
                .map(
                  (MapEntry<String, String> e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text("${e.value} (${e.key})"),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedState = value;
                _rows = <WxCounty>[];
                _error = null;
                _threatFilterMin = 0;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _hours,
                  decoration: const InputDecoration(
                    labelText: "Window",
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: const Color(0xFF111317),
                  items: const <DropdownMenuItem<int>>[
                    DropdownMenuItem<int>(value: 12, child: Text("12 h")),
                    DropdownMenuItem<int>(value: 24, child: Text("24 h")),
                    DropdownMenuItem<int>(value: 36, child: Text("36 h")),
                    DropdownMenuItem<int>(value: 48, child: Text("48 h")),
                    DropdownMenuItem<int>(value: 72, child: Text("72 h")),
                    DropdownMenuItem<int>(value: 96, child: Text("96 h")),
                    DropdownMenuItem<int>(value: 120, child: Text("120 h")),
                  ],
                  onChanged: (int? value) {
                    if (value == null) return;
                    setState(() {
                      _hours = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: _loading || _selectedState == null
                      ? null
                      : () => _loadForState(_selectedState!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DABrand.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    "Run",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Analog gauge cluster: DTI, max gust, crew load.
  Widget _buildAnalogCluster() {
    final int threat = _maxThreatIndex;
    final double gust = _maxGustState;
    final int crews = _totalCrews;

    final double width = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final double cardWidth =
        (width - 16 * 2 - 8 * 2).clamp(90.0, double.infinity) / 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF08090D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black87,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(
            width: cardWidth,
            child: _analogDial(
              label: "State DTI",
              valueLabel: "$threat",
              fraction: threat / 100.0,
              subtitle: "Threat index",
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _analogDial(
              label: "Max gust",
              valueLabel: "${gust.toStringAsFixed(0)} mph",
              fraction: (gust / 90.0).clamp(0.0, 1.0),
              subtitle: "Peak wind",
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _analogDial(
              label: "Crew index",
              valueLabel: crews.toString(),
              fraction: (_rows.isEmpty ? 0.0 : (crews / 200.0)).clamp(0.0, 1.0),
              subtitle: "Crews",
            ),
          ),
        ],
      ),
    );
  }

  Widget _analogDial({
    required String label,
    required String valueLabel,
    required double fraction,
    required String subtitle,
  }) {
    final double f = fraction.clamp(0.0, 1.0);

    Color arcColor;
    if (f >= 0.75) {
      arcColor = Colors.redAccent;
    } else if (f >= 0.5) {
      arcColor = Colors.deepOrangeAccent;
    } else if (f >= 0.25) {
      arcColor = Colors.yellowAccent.shade700;
    } else {
      arcColor = Colors.greenAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 90,
          height: 60,
          child: CustomPaint(
            painter: _HalfDialPainter(
              fraction: f,
              arcColor: arcColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valueLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRadarCard() {
    const String radarUrl =
        'https://tilecache.rainviewer.com/v2/radar/0/0/0/0/0.gif';

    return SizedBox(
      height: 210,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black87,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.black.withOpacity(0.85),
              ),
              child: Row(
                children: const <Widget>[
                  Icon(Icons.radar, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "National Radar",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      radarUrl,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                        return const Center(
                          child: Text(
                            "National Radar",
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatFilterRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                "Threat filter",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _buildThreatChip("All", 0),
              const SizedBox(width: 4),
              _buildThreatChip("25+", 25),
              const SizedBox(width: 4),
              _buildThreatChip("50+", 50),
              const SizedBox(width: 4),
              _buildThreatChip("75+", 75),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            "DTI = Divergent Threat Index (0 to 100)",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatChip(String label, int min) {
    final bool selected = _threatFilterMin == min;
    return GestureDetector(
      onTap: () {
        setState(() {
          _threatFilterMin = min;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? DABrand.orange : const Color(0xFF151623),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildCountyList() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_selectedState == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Center(
          child: Text(
            "Select a state and window, then tap Run.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final List<WxCounty> rows = _rows
        .where((WxCounty r) => r.threatIndex >= _threatFilterMin)
        .toList(growable: false);

    final List<Widget> cards = rows
        .map<Widget>((WxCounty r) => _buildCountyCard(r))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildThreatFilterRow(),
          const SizedBox(height: 6),
          if (_loading && rows.isEmpty)
            const Center(
              child: Text(
                "Running report...",
                style: TextStyle(color: Colors.white70),
              ),
            )
          else if (rows.isEmpty)
            const Center(
              child: Text(
                "No counties meet the current DTI filter or returned data.\n"
                "Try lowering the Threat filter or tapping All.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(children: cards),
        ],
      ),
    );
  }

  Widget _buildCountyCard(WxCounty r) {
    return GestureDetector(
      onTap: () => _showCountyDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: r.severityColor.withOpacity(0.85),
            width: 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: r.severityColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    "${r.county}, ${r.state}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.shield,
                      size: 18,
                      color: r.threatColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "DTI ${r.threatIndex}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: r.threatColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Wind dir: ${r.windDirection}   |   Max gust ${r.maxGust.toStringAsFixed(1)} mph",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Sustained ${r.maxSustained.toStringAsFixed(1)} mph   |   Prob ${(r.probabilityPercent).toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            if (r.directionAnomaly) ...<Widget>[
              const SizedBox(height: 4),
              const Text(
                "Non-routine wind direction flagged.",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _metricPill(
                    icon: Icons.bolt,
                    label: "Pred out",
                    value: _formatInt(r.predictedCustomersOut),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _metricPill(
                    icon: Icons.people_alt_rounded,
                    label: "Pop",
                    value: _formatInt(r.population),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _metricPill(
                    icon: Icons.groups_2_outlined,
                    label: "Crews",
                    value: r.crews.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151623),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: DABrand.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    )),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCountyDetail(WxCounty r) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF050509),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: r.threatColor,
                      child: const Text(
                        "DTI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${r.county}, ${r.state}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Divergent Threat Index: ${r.threatIndex}",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Predicted customers out: ${_formatInt(r.predictedCustomersOut)}",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Crews recommended: ${_formatInt(r.crews)}",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Population: ${_formatInt(r.population)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "Max gust: ${r.maxGust.toStringAsFixed(1)} mph",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Max sustained: ${r.maxSustained.toStringAsFixed(1)} mph",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Wind direction: ${r.windDirection}",
                  style: const TextStyle(fontSize: 14),
                ),
                if (r.directionAnomaly)
                  const Text(
                    "Non-routine direction: expect higher than normal tree and line stress.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orangeAccent,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  "Storm probability: ${(r.probabilityPercent).toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Model confidence: ${r.confidence}%",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Infrastructure & wind-direction analytics",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Infrastructure age and non-routine wind-direction metrics "
                  "are not yet wired to a trusted data source. No values are "
                  "fabricated here. These hooks are ready for when utilities "
                  "provide asset / GIS data and preferred wind-direction baselines.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                if (r.generatedAt != null)
                  Text(
                    "Generated: ${r.generatedAt}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                if (r.upstreamStamp != null)
                  Text(
                    "NWS upstream: ${r.upstreamStamp}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                Text(
                  "Source: ${r.source.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatInt(int v) {
    if (v >= 1000000) {
      final double m = v / 1000000.0;
      return "${m.toStringAsFixed(1)}M";
    }
    if (v >= 1000) {
      final double k = v / 1000.0;
      return "${k.toStringAsFixed(1)}k";
    }
    return v.toString();
  }
}

class _HalfDialPainter extends CustomPainter {
  _HalfDialPainter({
    required this.fraction,
    required this.arcColor,
  });

  final double fraction;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF1B1D26)
      ..style = PaintingStyle.fill;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(30)),
      bgPaint,
    );

    final double cx = size.width / 2;
    final double cy = size.height * 0.9;
    final double radius = size.height * 0.9;

    final Paint arcBg = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const double startAngle = math.pi;
    const double sweepAngle = math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcBg,
    );

    final Paint arcFg = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final double sweepActive = sweepAngle * fraction.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepActive,
      false,
      arcFg,
    );

    final double angle = startAngle + sweepActive;
    final double needleLen = radius * 0.7;
    final Paint needlePaint = Paint()
      ..color = arcColor
      ..strokeWidth = 2;

    final Offset needleEnd = Offset(
      cx + needleLen * math.cos(angle),
      cy + needleLen * math.sin(angle),
    );

    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      needlePaint,
    );

    final Paint hubPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), 3, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _HalfDialPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.arcColor != arcColor;
  }
}



