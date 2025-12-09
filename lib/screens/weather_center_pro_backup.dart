import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class WeatherCenterPro extends StatefulWidget {
  static const route = '/weather-center-pro';

  const WeatherCenterPro({super.key});

  @override
  State<WeatherCenterPro> createState() => _WeatherCenterProState();
}

class _WeatherCenterProState extends State<WeatherCenterPro>
    with SingleTickerProviderStateMixin {
  static const kBrandOrange = Color(0xFFFF6A00);
  static const kBrandBlack = Color(0xFF050509);
  // Page size used by Next / paging in the UI.
  // This value should match PAGE_SIZE in the Python backend.
  static const int kPageSize = 15;

  static const List<String> _stateOptions = <String>[
    'Select state',
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL',
    'GA','HI','ID','IL','IN','IA','KS','KY','LA',
    'ME','MD','MA','MI','MN','MS','MO','MT','NE',
    'NV','NH','NJ','NM','NY','NC','ND','OH','OK',
    'OR','PA','RI','SC','SD','TN','TX','UT','VT',
    'VA','WA','WV','WI','WY','DC','PR'
  ];

  String _selectedState = 'Select state';
  double _hours = 120;
  bool _loading = false;

  List<CountyForecast> _forecasts = <CountyForecast>[];

  late final AnimationController _tickerController;

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Backend call – full state (no "sample=10")
  // ---------------------------------------------------------------------------
  Future<List<CountyForecast>> _fetchStateForecast(String stateCode) async {
    final int hours = _hours.round().clamp(24, 120);
    final uri = Uri.parse(
      'https://da-wx-backend-1.onrender.com/api/wx'
      '?mode=State&state=$stateCode&hours=$hours',
    );

    final client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Backend status ${response.statusCode}');
      }

      final String body = await response.transform(utf8.decoder).join();
      final dynamic decoded = jsonDecode(body);

      if (decoded is! List) {
        throw Exception('Unexpected backend format (expected List).');
      }

      final List<CountyForecast> list = <CountyForecast>[];
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          list.add(CountyForecast.fromJson(item));
        } else if (item is Map) {
          final Map<String, dynamic> m = <String, dynamic>{};
          item.forEach((dynamic k, dynamic v) {
            m['$k'] = v;
          });
          list.add(CountyForecast.fromJson(m));
        }
      }
      return list;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _runForecast() async {
    if (_selectedState == 'Select state') {
      _showSnack('Pick a state first.');
      return;
    }
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final List<CountyForecast> fresh =
          await _fetchStateForecast(_selectedState);

      // Sort by GSI descending
      fresh.sort((CountyForecast a, CountyForecast b) =>
          b.gridStressIndex.compareTo(a.gridStressIndex));

      setState(() {
        _forecasts = fresh;
      });
    } catch (e) {
      _showSnack('Forecast error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Derived metrics (statewide)
  // ---------------------------------------------------------------------------
  double get _stateGsi {
    if (_forecasts.isEmpty) return 0.0;
    double sum = 0.0;
    for (final CountyForecast c in _forecasts) {
      sum += c.gridStressIndex;
    }
    return (sum / _forecasts.length).clamp(0.0, 1.0);
  }

  int get _stateLevel {
    final double g = _stateGsi;
    if (g >= 0.8) return 4;
    if (g >= 0.6) return 3;
    if (g >= 0.4) return 2;
    if (g >= 0.2) return 1;
    return 0;
  }

  String get _stateLevelLabel {
    final int lv = _stateLevel;
    switch (lv) {
      case 4:
        return 'Severe Grid Stress';
      case 3:
        return 'High Grid Stress';
      case 2:
        return 'Elevated Grid Stress';
      case 1:
        return 'Watch';
      default:
        return 'Normal';
    }
  }

  String get _activeThreatLabel {
    if (_forecasts.isEmpty) return 'No active threat';
    final bool anySevere =
        _forecasts.any((CountyForecast c) => c.severityLevel >= 3);
    // For now we’re wind-focused. Later you can expand to snow/ice/hurricane.
    return anySevere ? 'Wind (High Impact)' : 'Wind (Routine)';
  }

  int get _totalCrews {
    int sum = 0;
    for (final CountyForecast c in _forecasts) {
      sum += c.crews;
    }
    return sum;
  }

  int get _totalCustomersOut {
    int sum = 0;
    for (final CountyForecast c in _forecasts) {
      sum += c.predictedCustomersOut;
    }
    return sum;
  }

  double get _percentPopulationLevel3Plus {
    if (_forecasts.isEmpty) return 0.0;
    int popTotal = 0;
    int popHigh = 0;
    for (final CountyForecast c in _forecasts) {
      popTotal += c.population;
      if (c.gridStressIndex >= 0.6) {
        popHigh += c.population;
      }
    }
    if (popTotal == 0) return 0.0;
    return popHigh / popTotal;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: const <Widget>[
            SizedBox(width: 8),
            _BrandDot(),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Divergent Weather Center',
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _forecasts.isEmpty ? null : _exportCsv,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // Reactor background
          Positioned.fill(
            child: Image.asset(
              'assets/images/wx_reactor_wall.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildTicker(),
                  const SizedBox(height: 12),
                  _buildControls(),
                  const SizedBox(height: 12),
                  _buildGaugeAndRadarRow(),
                  const SizedBox(height: 12),
                  _buildAggregateRow(),
                  const SizedBox(height: 12),
                  _buildCountyLauncher(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    // ---------------------------------------------------------------------------
  // Ticker – Divergent marketing script + optional state status
  // ---------------------------------------------------------------------------
  Widget _buildTicker() {
    // Your exact marketing script (one full pass)
    const String marketingScript =
        'Divergent Supply represents over 200 manufacturers providing the materials utilities need | '
        'Divergent Storm Operations are always ready when needed | '
        'Gloves Sleeves Jumpers Grounds Hardhats Transformers wire and more | '
        'visit us today www.DivergentAlliance.com';

    // Optional state status appended to the loop (keeps it “live”).
    final double gsi = _stateGsi;
    final int pct = (gsi * 100).round();
    String statePart = '';
    if (_selectedState != 'Select state') {
      statePart =
          ' | ${_selectedState.toUpperCase()} grid stress: $pct% ($_stateLevelLabel) '
          '• Threat: $_activeThreatLabel '
          '• Projected customers out: ${_totalCustomersOut > 0 ? _totalCustomersOut.toString() : 'n/a'} '
          '• Crews: ${_totalCrews > 0 ? _totalCrews.toString() : 'n/a'}';
    }

    final String singleLine =
        statePart.isEmpty ? marketingScript : '$marketingScript$statePart';

    // Build a row of many copies so there is ALWAYS text on screen.
    List<Widget> _buildTickerCopies(TextStyle style) {
      const int copies = 8; // enough to cover several screen widths
      return List<Widget>.generate(
        copies,
        (_) => Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Text(
            singleLine,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: style,
          ),
        ),
      );
    }

    const TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      letterSpacing: 0.4,
    );

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF202124).withOpacity(0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedBuilder(
        animation: _tickerController,
        builder: (BuildContext context, Widget? child) {
          return ClipRect(
            child: LayoutBuilder(
              builder: (BuildContext ctx, BoxConstraints constraints) {
                final double width = constraints.maxWidth;
                // One full screen-width scroll per cycle -> faster, smoother.
                final double dx = -_tickerController.value * width;

                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Row(
                    children: _buildTickerCopies(textStyle),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Top controls
  // ---------------------------------------------------------------------------
  Widget _buildControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        SizedBox(
          width: 200,
          child: _glassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.public, color: kBrandOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF151515),
                      underline: const SizedBox.shrink(),
                      iconEnabledColor: kBrandOrange,
                      style: const TextStyle(color: Colors.white),
                      items: _stateOptions
                          .map(
                            (String s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (String? v) {
                        if (v == null) return;
                        setState(() {
                          _selectedState = v;
                          // Clear existing data – user must hit Run again.
                          _forecasts = <CountyForecast>[];
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: _glassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Forecast window (hours)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Slider(
                    min: 24,
                    max: 120,
                    divisions: 8,
                    value: _hours,
                    label: _hours.toStringAsFixed(0),
                    activeColor: kBrandOrange,
                    onChanged: (double v) {
                      setState(() {
                        _hours = v;
                      });
                    },
                  ),
                  Text(
                    '${_hours.toStringAsFixed(0)}h (up to 5 days)',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _RunButton(
          loading: _loading,
          enabled: _selectedState != 'Select state',
          onRun: _runForecast,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Gauge + radar row
  // ---------------------------------------------------------------------------
  Widget _buildGaugeAndRadarRow() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 720;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildGaugeCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildRadarCard()),
            ],
          );
        } else {
          return Column(
            children: <Widget>[
              _buildGaugeCard(),
              const SizedBox(height: 12),
              _buildRadarCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildGaugeCard() {
    final double gsi = _stateGsi;
    final int level = _stateLevel;
    final int pct = (gsi * 100).round();

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.speed_rounded, color: kBrandOrange),
                const SizedBox(width: 8),
                const Text(
                  'Divergent Grid Stress Index',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: kBrandOrange.withOpacity(0.9),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    'Level $level',
                    style: const TextStyle(
                      color: kBrandOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _GaugePainter(gsi),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stateLevelLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Active threat: $_activeThreatLabel',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _forecasts.isEmpty
                  ? 'Select a state and run live forecast to energize the grid stress index.'
                  : 'GSI blends max gust, outage probability, forecast load, and severity into a single statewide stress number.',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarCard() {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: const <Widget>[
                Icon(Icons.radar_rounded, color: kBrandOrange),
                SizedBox(width: 8),
                Text(
                  'Reactor Radar Scope',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Live NWS CONUS radar mosaic with pan & zoom. Use this for quick situational awareness alongside the grid stress index.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Container(
                    color: Colors.black,
                    child: Image.network(
                      'https://https://radar.weather.gov/ridge/standard/CONUS_0.gif/ridge/standard/CONUS_0.gif/ridge/standard/CONUS_0.gif',
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext _, Object __, StackTrace? ___) {
                        // Fallback: stylized scope if radar URL fails.
                        return CustomPaint(
                          size: const Size(400, 400),
                          painter: _RadarPainter(),
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

  // ---------------------------------------------------------------------------
  // Aggregate KPIs
  // ---------------------------------------------------------------------------
  Widget _buildAggregateRow() {
    final int totalCrews = _totalCrews;
    final int customers = _totalCustomersOut;
    final double pctHigh = _percentPopulationLevel3Plus;
    final String pctHighText =
        _forecasts.isEmpty ? '—' : '${(pctHigh * 100).toStringAsFixed(0)}%';

    final List<Widget> cards = <Widget>[
      _kpiTile(
        'Total crews recommended',
        totalCrews > 0 ? '$totalCrews' : '—',
        Icons.groups_rounded,
      ),
      _kpiTile(
        'Predicted customers out',
        customers > 0 ? customers.toString() : '—',
        Icons.bolt_rounded,
      ),
      _kpiTile(
        'Population in Level 3+',
        pctHighText,
        Icons.warning_amber_rounded,
      ),
      _kpiTile(
        'Divergent confidence (backend)',
        _forecasts.isEmpty
            ? '—'
            : '${_forecasts.map((CountyForecast c) => c.confidence).fold<int>(0, (int a, int b) => a + b) ~/ _forecasts.length}%',
        Icons.verified_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 720;
        if (wide) {
          return Row(
            children: <Widget>[
              for (final Widget w in cards) Expanded(child: w),
            ],
          );
        } else {
          return Column(
            children: <Widget>[
              for (final Widget w in cards) ...<Widget>[
                w,
                const SizedBox(height: 8),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _kpiTile(String title, String value, IconData icon) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: kBrandOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // County explorer launcher (results on a new page)
  // ---------------------------------------------------------------------------
  Widget _buildCountyLauncher() {
    if (_forecasts.isEmpty) {
      return _glassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const <Widget>[
              Icon(Icons.info_outline, color: kBrandOrange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Run a live forecast for a state, then open the County Explorer to drill into every county\'s grid stress, outage risk, and crew plan.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(Icons.map_rounded, color: kBrandOrange),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'County Explorer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext ctx) => CountyExplorerPage(
                      stateCode: _selectedState,
                      forecasts: _forecasts,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open'),
              style: TextButton.styleFrom(
                foregroundColor: kBrandOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CSV export (AppBar icon)
  // ---------------------------------------------------------------------------
  void _exportCsv() {
    if (_forecasts.isEmpty) {
      _showSnack('Nothing to export – run a forecast first.');
      return;
    }

    final StringBuffer sb = StringBuffer();
    sb.writeln([
      'county',
      'state',
      'expectedGust',
      'expectedSustained',
      'maxGust',
      'maxSustained',
      'probability',
      'crews',
      'severity',
      'confidence',
      'population',
      'predictedCustomersOut',
      'gridStressIndex',
      'gridStressLevel',
      'generatedAt',
      'source',
      'upstreamStamp',
    ].join(','));

    for (final CountyForecast c in _forecasts) {
      sb.writeln([
        c.county,
        c.state,
        c.expectedGust.toStringAsFixed(1),
        c.expectedSustained.toStringAsFixed(1),
        c.maxGust.toStringAsFixed(1),
        c.maxSustained.toStringAsFixed(1),
        c.probability.toStringAsFixed(2),
        c.crews,
        c.severityLevel,
        c.confidence,
        c.population,
        c.predictedCustomersOut,
        c.gridStressIndex.toStringAsFixed(3),
        c.gsiLevel,
        c.generatedAt?.toIso8601String() ?? '',
        c.source,
        c.upstreamStamp,
      ].join(','));
    }

    final String csv = sb.toString();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text(
            'CSV ready',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: kBrandOrange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF202020),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ===================================================================
// Shared glass card helper
// ===================================================================
Widget _glassCard({required Widget child}) {
  final BorderRadius radius = BorderRadius.circular(16);
  return Container(
    decoration: BoxDecoration(
      borderRadius: radius,
      border: Border.all(
        color: _WeatherCenterProState.kBrandOrange.withOpacity(0.55),
        width: 0.9,
      ),
      gradient: const LinearGradient(
        colors: <Color>[
          Color(0x26FFFFFF),
          Color(0x14000000),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withOpacity(0.8),
          blurRadius: 18,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: _WeatherCenterProState.kBrandOrange.withOpacity(0.25),
          blurRadius: 26,
          spreadRadius: 0.5,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: child,
      ),
    ),
  );
}

// ===================================================================
// Brand dot
// ===================================================================
class _BrandDot extends StatelessWidget {
  const _BrandDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _WeatherCenterProState.kBrandOrange,
      ),
    );
  }
}

// ===================================================================
// Mad-scientist gauge painter
// ===================================================================
class _GaugePainter extends CustomPainter {
  final double gsi;

  _GaugePainter(this.gsi);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.78);
    final double radius = math.min(size.width, size.height * 1.6) / 2.3;

    const double startAngle = math.pi;
    const double sweepAngle = math.pi;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint base = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, base);

    final double clampedGsi = gsi.clamp(0.0, 1.0);
    final double activeSweep = sweepAngle * clampedGsi;

    final Paint active = Paint()
      ..shader = ui.Gradient.linear(
        Offset(arcRect.left, arcRect.top),
        Offset(arcRect.right, arcRect.bottom),
        <Color>[
          _WeatherCenterProState.kBrandOrange,
          const Color(0xFFFFE082),
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, activeSweep, false, active);

    final Paint tickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;

    for (int i = 0; i <= 10; i++) {
      final double t = i / 10.0;
      final double angle = startAngle + sweepAngle * t;
      final double inner = radius - 10;
      final double outer = radius + 4;

      final Offset p1 = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      final Offset p2 = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    final double pointerAngle = startAngle + activeSweep;
    final double pointerLen = radius + 14;

    final Offset needleEnd = Offset(
      center.dx + pointerLen * math.cos(pointerAngle),
      center.dy + pointerLen * math.sin(pointerAngle),
    );

    final Paint needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2;

    canvas.drawLine(center, needleEnd, needlePaint);

    final Paint hub = Paint()
      ..shader = ui.Gradient.radial(
        center,
        9,
        <Color>[
          _WeatherCenterProState.kBrandOrange,
          Colors.white,
        ],
      );

    canvas.drawCircle(center, 6, hub);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.gsi != gsi;
  }
}

// ===================================================================
// Radar painter (fallback scope)
// ===================================================================
class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double maxR = math.min(size.width, size.height) / 2.2;

    final Paint bg = Paint()..color = const Color(0xFF020508);
    canvas.drawRect(Offset.zero & size, bg);

    final Paint ring = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxR * (i / 4.0), ring);
    }

    final Paint cross = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - maxR, center.dy),
      Offset(center.dx + maxR, center.dy),
      cross,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxR),
      Offset(center.dx, center.dy + maxR),
      cross,
    );

    final Paint glow = Paint()
      ..color = _WeatherCenterProState.kBrandOrange.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxR * 0.15, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===================================================================
// Run button
// ===================================================================
class _RunButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onRun;

  const _RunButton({
    required this.loading,
    required this.enabled,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 12,
          backgroundColor: !enabled
              ? Colors.white10
              : (loading
                  ? Colors.white70
                  : _WeatherCenterProState.kBrandOrange.withOpacity(0.95)),
          foregroundColor: enabled ? Colors.black : Colors.white38,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(
          loading ? Icons.autorenew_rounded : Icons.play_arrow_rounded,
        ),
        label: Text(
          loading ? 'Running live forecast...' : 'Run live forecast',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        onPressed: (!enabled || loading) ? null : onRun,
      ),
    );
  }
}

// ===================================================================
// Helpers for ticker and normalization
// ===================================================================
String _repeatTicker(String text, int times) {
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < times; i++) {
    buf.write(text);
    buf.write('   ');
  }
  return buf.toString();
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) {
    final double? parsed = double.tryParse(v.trim());
    if (parsed != null) return parsed;
  }
  return 0.0;
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final int? parsed = int.tryParse(v.trim());
    if (parsed != null) return parsed;
  }
  return 0;
}

/// Normalize value in [lo, hi] to 0–1.
double _norm(double value, double lo, double hi) {
  final double span = hi - lo;
  if (span <= 0) return 0.0;
  final double t = (value - lo) / span;
  if (t < 0) return 0.0;
  if (t > 1) return 1.0;
  return t;
}

// ===================================================================
// CountyForecast + Divergent Grid Stress Index logic
// ===================================================================
class CountyForecast {
  final String county;
  final String state;
  final double expectedGust;
  final double expectedSustained;
  final double maxGust;
  final double maxSustained;
  final double probability; // 0..1
  final int crews;
  final int severityLevel; // 0..4
  final int confidence;
  final int population;
  final int predictedCustomersOut;
  final DateTime? generatedAt;
  final String source;
  final String upstreamStamp;

  /// Divergent Grid Stress Index (0..1)
  final double gridStressIndex;

  /// Discrete level 0–4 derived from GSI
  final int gsiLevel;

  CountyForecast({
    required this.county,
    required this.state,
    required this.expectedGust,
    required this.expectedSustained,
    required this.maxGust,
    required this.maxSustained,
    required this.probability,
    required this.crews,
    required this.severityLevel,
    required this.confidence,
    required this.population,
    required this.predictedCustomersOut,
    required this.generatedAt,
    required this.source,
    required this.upstreamStamp,
    required this.gridStressIndex,
    required this.gsiLevel,
  });

  factory CountyForecast.fromJson(Map<String, dynamic> j) {
    final String county = (j['county'] ?? '').toString();
    final String state = (j['state'] ?? '').toString();

    final double expectedGust = _asDouble(j['expectedGust']);
    final double expectedSustained = _asDouble(j['expectedSustained']);
    final double maxGust = _asDouble(j['maxGust']);
    final double maxSustained = _asDouble(j['maxSustained']);
    final double probability = _asDouble(j['probability']).clamp(0.0, 1.0);
    final int crews = _asInt(j['crews']);
    final int severityLevel = _asInt(j['severity']);
    final int confidence = _asInt(j['confidence']);
    final int population = _asInt(j['population']);
    final int predictedCustomersOut = _asInt(j['predicted_customers_out']);

    DateTime? generatedAt;
    final dynamic g = j['generatedAt'];
    if (g is String) {
      try {
        generatedAt = DateTime.parse(g).toUtc();
      } catch (_) {
        generatedAt = null;
      }
    }

    final String source = (j['source'] ?? '').toString();
    final String upstreamStamp = (j['upstreamStamp'] ?? '').toString();

    // Divergent Grid Stress Index:
    //   gustTerm:     max gust 25–75 mph
    //   probTerm:     outage prob 0–1
    //   loadTerm:     customers out as fraction of 40% of population
    //   severityTerm: severity level 1–4 mapped to 0–1
    //
    // GSI = 0.40 * gustTerm
    //     + 0.25 * probTerm
    //     + 0.20 * loadTerm
    //     + 0.15 * severityTerm

    final double gustTerm = _norm(maxGust, 25, 75);
    final double loadTerm = (population > 0)
        ? (predictedCustomersOut / (population * 0.40)).clamp(0.0, 1.0)
        : 0.0;
    final double severityTerm =
        severityLevel <= 0 ? 0.0 : _norm(severityLevel.toDouble(), 1.0, 4.0);
    final double probTerm = probability;

    double gsi = 0.40 * gustTerm +
        0.25 * probTerm +
        0.20 * loadTerm +
        0.15 * severityTerm;
    gsi = gsi.clamp(0.0, 1.0);

    int level;
    if (gsi >= 0.80) {
      level = 4;
    } else if (gsi >= 0.60) {
      level = 3;
    } else if (gsi >= 0.40) {
      level = 2;
    } else if (gsi >= 0.20) {
      level = 1;
    } else {
      level = 0;
    }

    return CountyForecast(
      county: county,
      state: state,
      expectedGust: expectedGust,
      expectedSustained: expectedSustained,
      maxGust: maxGust,
      maxSustained: maxSustained,
      probability: probability,
      crews: crews,
      severityLevel: severityLevel,
      confidence: confidence,
      population: population,
      predictedCustomersOut: predictedCustomersOut,
      generatedAt: generatedAt,
      source: source,
      upstreamStamp: upstreamStamp,
      gridStressIndex: gsi,
      gsiLevel: level,
    );
  }

  String get levelLabel {
    switch (gsiLevel) {
      case 4:
        return 'Severe';
      case 3:
        return 'High';
      case 2:
        return 'Elevated';
      case 1:
        return 'Watch';
      default:
        return 'Normal';
    }
  }
}

// ===================================================================
// County Explorer + Detail (drill-down tiles) – PAGED + THREAT FILTER
// ===================================================================
class CountyExplorerPage extends StatefulWidget {
  final String stateCode;
  final List<CountyForecast> forecasts;

  const CountyExplorerPage({
    super.key,
    required this.stateCode,
    required this.forecasts,
  });

  @override
  State<CountyExplorerPage> createState() => _CountyExplorerPageState();
}

class _CountyExplorerPageState extends State<CountyExplorerPage> {
  static const int _pageSize = 15;
  int _page = 0;
  int _minLevel = 0; // 0 = All, 1 = Level 1+, etc.

  List<CountyForecast> get _sortedFiltered {
    // Sort by Grid Stress Index (descending)
    final List<CountyForecast> all =
        List<CountyForecast>.from(widget.forecasts);
    all.sort(
      (CountyForecast a, CountyForecast b) =>
          b.gridStressIndex.compareTo(a.gridStressIndex),
    );

    if (_minLevel <= 0) {
      return all;
    }

    return all.where((CountyForecast c) => c.gsiLevel >= _minLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<CountyForecast> filtered = _sortedFiltered;
    final int totalCount = filtered.length;
    final int totalPages =
        totalCount == 0 ? 1 : ((totalCount + _pageSize - 1) ~/ _pageSize);

    // Keep page index safe
    if (_page >= totalPages) {
      _page = totalPages - 1;
    }
    if (_page < 0) {
      _page = 0;
    }

    final int start = _page * _pageSize;
    final int end =
        totalCount == 0 ? 0 : math.min(start + _pageSize, totalCount);
    final List<CountyForecast> slice =
        totalCount == 0 ? <CountyForecast>[] : filtered.sublist(start, end);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('County Explorer – ${widget.stateCode}'),
      ),
      body: Column(
        children: <Widget>[
          // Threat filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _buildFilterRow(totalCount),
          ),
          const SizedBox(height: 4),
          // Paged list
          Expanded(
            child: slice.isEmpty
                ? const Center(
                    child: Text(
                      'No counties match the current filter.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: slice.length,
                    separatorBuilder: (BuildContext _, int __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final CountyForecast c = slice[index];
                      final int gsiPct =
                          (c.gridStressIndex * 100).round();
                      final String lvl =
                          'L${c.gsiLevel} – ${c.levelLabel}';

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext ctx) =>
                                  CountyDetailPage(county: c),
                            ),
                          );
                        },
                        child: _glassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.bolt_rounded,
                                  color: _WeatherCenterProState.kBrandOrange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        '${c.county}, ${c.state}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'GSI $gsiPct% • $lvl',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Gust ${c.maxGust.toStringAsFixed(0)} mph • '
                                        'Outage prob ${(c.probability * 100).toStringAsFixed(0)}% • '
                                        'Cust out ${c.predictedCustomersOut}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _WeatherCenterProState
                                          .kBrandOrange
                                          .withOpacity(0.9),
                                    ),
                                  ),
                                  child: Text(
                                    'Crews ${c.crews}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Pager bar with Previous / Next
          _buildPagerBar(
            totalCount: totalCount,
            totalPages: totalPages,
            startIndex: totalCount == 0 ? 0 : start + 1,
            endIndex: totalCount == 0 ? 0 : end,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(int totalCount) {
    return Row(
      children: <Widget>[
        const Icon(Icons.filter_alt_outlined,
            size: 18, color: Colors.white70),
        const SizedBox(width: 6),
        const Text(
          'Threat level:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        _severityChip('All', 0),
        _severityChip('Level 1+', 1),
        _severityChip('Level 2+', 2),
        _severityChip('Level 3+', 3),
        _severityChip('Level 4', 4),
        const Spacer(),
        Text(
          totalCount == 0 ? 'No counties' : '$totalCount counties',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _severityChip(String label, int level) {
    final bool selected = _minLevel == level;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 11,
          ),
        ),
        selected: selected,
        onSelected: (bool v) {
          if (!v) return;
          setState(() {
            _minLevel = level;
            _page = 0; // reset to first page when filter changes
          });
        },
        selectedColor:
            _WeatherCenterProState.kBrandOrange.withOpacity(0.95),
        backgroundColor: Colors.white10,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildPagerBar({
    required int totalCount,
    required int totalPages,
    required int startIndex,
    required int endIndex,
  }) {
    final bool canPrev = _page > 0;
    final bool canNext = (_page + 1) < totalPages && totalCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Text(
            totalCount == 0
                ? 'No results'
                : 'Showing $startIndex–$endIndex of $totalCount',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: canPrev
                ? () {
                    setState(() {
                      _page = _page - 1;
                      if (_page < 0) _page = 0;
                    });
                  }
                : null,
            child: const Text(
              'Previous',
              style: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: canNext
                ? () {
                    setState(() {
                      _page = _page + 1;
                    });
                  }
                : null,
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}


class CountyDetailPage extends StatelessWidget {
  final CountyForecast county;

  const CountyDetailPage({super.key, required this.county});

  @override
  Widget build(BuildContext context) {
    final int gsiPct = (county.gridStressIndex * 100).round();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${county.county}, ${county.state}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Grid Stress: $gsiPct% – ${county.levelLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _metricPill(
                      'Expected gust',
                      '${county.expectedGust.toStringAsFixed(0)} mph',
                    ),
                    _metricPill(
                      'Max gust',
                      '${county.maxGust.toStringAsFixed(0)} mph',
                    ),
                    _metricPill(
                      'Outage probability',
                      '${(county.probability * 100).toStringAsFixed(0)}%',
                    ),
                    _metricPill(
                      'Predicted customers out',
                      county.predictedCustomersOut.toString(),
                    ),
                    _metricPill('Crews recommended', '${county.crews}'),
                    _metricPill('Population', county.population.toString()),
                    _metricPill(
                      'Backend confidence',
                      '${county.confidence}%',
                    ),
                    _metricPill('Severity', 'Level ${county.severityLevel}'),
                    if (county.generatedAt != null)
                      _metricPill(
                        'Generated',
                        county.generatedAt!.toIso8601String(),
                      ),
                    _metricPill('Source', county.source),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recommendation: Consider pre-patrol of older infrastructure and critical feeders in Level 3+ counties, especially where forecast gusts exceed 50 mph and outage probability is above 70%.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _metricPill(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: _WeatherCenterProState.kBrandOrange.withOpacity(0.6),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

