import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// How the Weather Center is querying the backend.
/// Kept here so UI and service stay in sync.
enum WxFilterMode {
  national,
  region,
  state,
}

class WxBackendService {
  WxBackendService._();

  // Render backend base URL – single source of truth.
  static const String _baseUrl = 'https://da-wx-backend-1.onrender.com/api/wx';
  static const Map<String, List<String>> _regionStates = {

    'Midwest': <String>[

      'Ohio',

      'Michigan',

      'Indiana',

      'Illinois',

      'Wisconsin',

      'Minnesota',

      'Iowa',

      'Missouri',

      'North Dakota',

      'South Dakota',

      'Nebraska',

      'Kansas',

    ],

  };


  /// Nationwide (no region) – default sample size = 80
  static Future<List<Map<String, dynamic>>> fetchNationwide({
    int hours = 24,
    int sample = 25,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?mode=National&hours=$hours&sample=$sample',
    );
    return _fetch(uri);
  }

  /// Region view (e.g. Midwest, Northeast).

  /// Uses backend Region endpoint, then falls back to aggregating by states

  /// if the backend returns no rows.

  static Future<List<Map<String, dynamic>>> fetchRegion({

    required String region,

    int hours = 24,

    int sample = 25,

  }) async {

    // Primary: backend region endpoint.

    final uri = Uri.parse(

      "$_baseUrl?mode=Region&region=$region&hours=$hours&sample=$sample",

    );

    final primary = await _fetch(uri);

    if (primary.isNotEmpty) {

      return primary;

    }

    // Fallback: aggregate via states that belong to this region.

    final states = _regionStates[region];

    if (states == null || states.isEmpty) {

      return primary;

    }

    final List<Map<String, dynamic>> combined = [];

    for (final s in states) {

      try {

        final rows = await fetchState(

          state: s,

          hours: hours,

          sample: sample,

        );

        combined.addAll(rows);

      } catch (_) {

        // Ignore individual state failures in fallback.

      }

    }

    return combined;

  }


  /// Single‑state view – slightly smaller sample by default.
  static Future<List<Map<String, dynamic>>> fetchState({
    required String state,
    int hours = 24,
    int sample = 40,
  }) async {
    final uri = Uri.parse(
        "$_baseUrl?mode=State&state=$state&hours=$hours&sample=$sample");
    return _fetch(uri);
  }

  /// Shared HTTP + JSON handling.
  /// In release, do NOT silently swallow errors. Throw so UI can show them.
  static Future<List<Map<String, dynamic>>> _fetch(Uri uri) async {
    debugPrint('WxBackendService GET ' + uri.toString());
    try {
      final response = await http.get(uri);
      debugPrint('WxBackendService status: ' + response.statusCode.toString());

      if (response.statusCode != 200) {
        throw Exception(
          'WxBackendService non-200: ' +
              response.statusCode.toString() +
              ' ' +
              response.body.toString(),
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map<String, dynamic>) {
        final rows = decoded['rows'];
        if (rows is List) {
          return rows.cast<Map<String, dynamic>>();
        }
      }

      throw Exception('WxBackendService unexpected JSON shape: ' +
          decoded.runtimeType.toString());
    } catch (e, st) {
      debugPrint('WxBackendService _fetch error: ' + e.toString());
      debugPrint(st.toString());
      rethrow;
    }
  }



  /// Normalize the backend record into the exact shape the UI expects.
  ///
  /// This keeps backwards compatibility with previous field names and
  /// ensures the cards never break if the backend shuffles keys slightly.
  static Map<String, dynamic> _normalizeRow(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final r = Map<String, dynamic>.from(raw as Map);

    // County / State labels
    final county = (r["County"] ??
            r["county"] ??
            r["countyName"] ??
            r["county_name"] ??
            "")
        .toString();

    final state = (r["State"] ??
            r["state"] ??
            r["state_name"] ??
            r["stateName"] ??
            "")
        .toString();

    // Severity – support multiple possible keys and clamp to 0–3.
    final rawSeverity = r["Severity"] ??
        r["severity"] ??
        r["threat_level"] ??
        r["threatLevel"] ??
        r["maxSeverity"] ??
        r["max_severity"] ??
        0;

    final sevInt = int.tryParse(rawSeverity.toString()) ?? 0;
    final sev = sevInt.clamp(0, 3);

    // Winds
    final expectedGust = _num(
      r["Expected Gust"] ??
          r["expectedGust"] ??
          r["expected_gust"] ??
          r["gust"],
    );

    final expectedSustained = _num(
      r["Expected Sustained"] ??
          r["expectedSustained"] ??
          r["expected_sustained"] ??
          r["sustained"],
    );

    final maxGust = _num(
      r["Max Gust"] ??
          r["maxGust"] ??
          r["max_gust"] ??
          r["peak_gust"] ??
          r["peakGust"] ??
          expectedGust,
    );

    final maxSustained = _num(
      r["Max Sustained"] ??
          r["maxSustained"] ??
          r["max_sustained"] ??
          expectedSustained,
    );

    // Probability / population
    final prob = _num(
      r["Probability"] ?? r["probability"] ?? r["prob"],
    );

    final population =
        r["Population"] ?? r["population"] ?? r["pop"] ?? 0;

    // Crews
    final crews = (r["Crews"] ??
            r["crews"] ??
            r["crewRecommendation"] ??
            r["crew_recommendation"] ??
            r["crewRec"] ??
            r["crew_rec"] ??
            0)
        .toInt();

    // Customers out
    final customersOut = (r["Customers Out"] ??
            r["customersOut"] ??
            r["Predicted Customers Out"] ??
            r["predicted_customers_out"] ??
            r["customers_out"] ??
            r["expected_customers_out"] ??
            0)
        .toInt();

    return {
      "county": county,
      "state": state,
      "severity": sev.toString(),
      "rawSeverity": rawSeverity,
      "expectedGust": expectedGust,
      "expectedSustained": expectedSustained,
      "maxGust": maxGust,
      "maxSustained": maxSustained,
      "probability": prob,
      "population": population,
      "customersOut": customersOut,
      "predicted_customers_out": customersOut,
      "expected_customers_out": customersOut,
      "expectedCustomersOut": customersOut,
      "crews": crews,
      "crewRecommendation": crews,
    };
  }


  // Exposed helpers so UI can use normalized rows from backend
  static Map<String, dynamic> normalizeRow(dynamic raw) => _normalizeRow(raw);

  static List<Map<String, dynamic>> normalizeRows(List<dynamic> list) =>
      list.map(_normalizeRow).toList();
  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
  // ---------------------------------------------------------------------------
  // Warm-up ping to wake the Render backend (safe, silent, fire-and-forget)
  // ---------------------------------------------------------------------------
  static Future<void> warm() async {
    try {
      final uri = Uri.parse('https://da-wx-backend-1.onrender.com/health');

      // Fire the request with short timeout
      await http.get(uri).timeout(const Duration(seconds: 10));

      print('Warm ping complete');
    } catch (e) {
      print('Warm ping failed: $e');
    }
  }
}




