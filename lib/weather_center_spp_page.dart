import "dart:convert";
import "package:flutter/material.dart";
import "package:syncfusion_flutter_gauges/gauges.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:http/http.dart" as http;

import "weather_report_model.dart";

// TODO: set this to your real backend base URL, no trailing slash.
const String backendBaseUrl = "https://da-wx-backend-1.onrender.com";

Future<WeatherReport> fetchWeatherReport(String state, int hoursAhead) async {
  final uri = Uri.parse(backendBaseUrl + "/api/wx").replace(
    queryParameters: <String, String>{
      "mode": "state",        // change to match your API
      "state": state,
      "hoursAhead": "$hoursAhead",
    },
  );

  final resp = await http.get(
    uri,
    headers: <String, String>{
      "Accept": "application/json",
    },
  );

  if (resp.statusCode != 200) {
    throw Exception("Backend error " + resp.statusCode.toString() + ": " + resp.body);
  }

  final dynamic decoded = json.decode(resp.body);
  Map<String, dynamic> payload;

  if (decoded is Map<String, dynamic>) {
    if (decoded.containsKey("data") && decoded["data"] is Map<String, dynamic>) {
      payload = decoded["data"] as Map<String, dynamic>;
    } else {
      payload = decoded;
    }
  } else {
    throw Exception("Unexpected JSON structure from backend");
  }

  return WeatherReport.fromJson(payload);
}

class WeatherCenterSPPPage extends StatefulWidget {
  const WeatherCenterSPPPage({Key? key}) : super(key: key);

  @override
  State<WeatherCenterSPPPage> createState() => _WeatherCenterSPPPageState();
}

class _WeatherCenterSPPPageState extends State<WeatherCenterSPPPage> {
  final List<String> _states = <String>[
    "Texas",
    "Louisiana",
    "Florida",
    "Georgia",
    "South Carolina",
    "North Carolina",
    "Alabama",
    "Virginia",
    "Arkansas",
    "Tennessee",
  ];

  final List<int> _hoursAhead = <int>[24, 48, 72, 96, 120];

  String _selectedState = "Texas";
  int _selectedHours = 24;

  WeatherReport? _report;
  bool _loading = false;

  Future<void> _runReport() async {
    setState(() {
      _loading = true;
    });

    try {
      final WeatherReport result = await fetchWeatherReport(_selectedState, _selectedHours);
      setState(() {
        _report = result;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double h = constraints.maxHeight;
            final double w = constraints.maxWidth;

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/divergent_weather_panel.png",
                    fit: BoxFit.cover,
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.06,
                      vertical: h * 0.06,
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: h * 0.07),
                        _buildTopSelectorSlot(w, h),
                        SizedBox(height: h * 0.03),
                        _buildRunReportButton(w, h),
                        SizedBox(height: h * 0.025),
                        _buildGaugeRow(w, h),
                        SizedBox(height: h * 0.025),
                        _buildStatsRowOne(),
                        SizedBox(height: h * 0.015),
                        _buildStatsRowTwo(),
                        SizedBox(height: h * 0.025),
                        _buildRadarSlot(h),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSelectorSlot(double w, double h) {
    return Container(
      height: h * 0.09,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedState,
                dropdownColor: Colors.black,
                iconEnabledColor: Colors.orangeAccent,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                items: _states
                    .map(
                      (String s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      ),
                    )
                    .toList(),
                onChanged: (String? val) {
                  if (val == null) return;
                  setState(() {
                    _selectedState = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedHours,
                dropdownColor: Colors.black,
                iconEnabledColor: Colors.orangeAccent,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                items: _hoursAhead
                    .map(
                      (int h) => DropdownMenuItem<int>(
                        value: h,
                        child: Text(h.toString() + " hrs"),
                      ),
                    )
                    .toList(),
                onChanged: (int? val) {
                  if (val == null) return;
                  setState(() {
                    _selectedHours = val;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunReportButton(double w, double h) {
    return SizedBox(
      height: h * 0.055,
      width: w * 0.55,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _runReport,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildGaugeRow(double w, double h) {
    final WeatherReport? r = _report;

    final double wind   = r != null ? r.windSpeed      : 0.0;
    final double gust   = r != null ? r.gustSpeed      : 0.0;
    final double rain   = r != null ? r.precipitation  : 0.0;
    final double press  = r != null ? r.pressure       : 950.0;

    return SizedBox(
      height: h * 0.13,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildGauge("WIND", wind, 0, 100),
          _buildGauge("GUST", gust, 0, 120),
          _buildGauge("RAIN", rain, 0, 5),
          _buildGauge("PRESS", press, 950, 1050),
        ],
      ),
    );
  }

  Widget _buildGauge(String label, double value, double min, double max) {
    final double clamped = value < min ? min : (value > max ? max : value);

    return Expanded(
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: min,
            maximum: max,
            showLabels: false,
            showTicks: false,
            axisLineStyle: AxisLineStyle(
              thickness: 0.12,
              thicknessUnit: GaugeSizeUnit.factor,
              color: Colors.orange.withOpacity(0.3),
            ),
            pointers: <GaugePointer>[
              NeedlePointer(
                value: clamped,
                needleLength: 0.7,
                needleColor: Colors.orangeAccent,
                knobStyle: const KnobStyle(
                  color: Colors.orangeAccent,
                  knobRadius: 0.04,
                ),
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                angle: 90,
                positionFactor: 1.4,
                widget: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRowOne() {
    final WeatherReport? r = _report;
    final String risk = r != null ? r.outageRisk.toStringAsFixed(0) : "--";
    final String temp = r != null ? r.temp.toStringAsFixed(0) : "--";

    return Row(
      children: <Widget>[
        Expanded(
          child: _statBox(
            title: "OUTAGE RISK %",
            value: risk,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox(
            title: "TEMP (°F)",
            value: temp,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRowTwo() {
    final WeatherReport? r = _report;
    final String rain = r != null ? r.precipitation.toStringAsFixed(2) : "--";
    final String lightning = r != null ? r.lightningRate.toStringAsFixed(0) : "--";
    final String hours = _selectedHours.toString();

    return Row(
      children: <Widget>[
        Expanded(
          child: _statBox(
            title: "RAIN (in/hr)",
            value: rain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            title: "LIGHTNING /hr",
            value: lightning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            title: "HOURS AHEAD",
            value: hours,
          ),
        ),
      ],
    );
  }

  Widget _statBox({required String title, required String value}) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.80),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSlot(double h) {
    return Container(
      height: h * 0.24,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(32.5, -92.5),
          initialZoom: 4.7,
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.divergentalliance.app",
          ),
        ],
      ),
    );
  }
}
