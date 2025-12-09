import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple wind summary in mph for wxpro_run_sheet.dart.
class WindSummary {
  final double maxGustMph;
  final double maxSustainedMph;

  WindSummary({
    required this.maxGustMph,
    required this.maxSustainedMph,
  });
}

/// NWS-based wind helper for wxpro_run_sheet.dart.
///
/// This uses the official api.weather.gov "points" endpoint to look up the
/// local grid and then pulls the hourly forecast. It returns the maximum
/// gust and sustained wind (in mph) over the next `windowHours`.
///
/// If NWS does not return usable data or an HTTP error occurs, this method
/// throws; wxpro_run_sheet.dart already catches errors and shows a snackbar
/// instead of silently pretending there is no risk.
class WxService {
  static const String _nwsBase = 'https://api.weather.gov';

  static const Map<String, String> _headers = {
    'User-Agent':
        'DivergentWx/1.0 (https://www.DivergentAlliance.com, support@divergentalliance.com)',
    'Accept': 'application/geo+json, application/json',
  };

  static Future<WindSummary> fetchWind({
    required double lat,
    required double lon,
    required int windowHours,
  }) async {
    // Clamp the look-ahead window to something NWS can realistically serve.
    int hours = windowHours;
    if (hours < 1) hours = 1;
    if (hours > 72) hours = 72;

    // --------------------------------------------------------------
    // 1) Points lookup -> gives us forecastHourly URL for the grid.
    // --------------------------------------------------------------
    final pointsUri = Uri.parse('$_nwsBase/points/$lat,$lon');
    final pointsResp = await http.get(pointsUri, headers: _headers);

    if (pointsResp.statusCode != 200) {
      throw Exception('NWS points lookup ${pointsResp.statusCode}');
    }

    final Map<String, dynamic> pointsJson =
        jsonDecode(pointsResp.body) as Map<String, dynamic>;
    final Map<String, dynamic>? props =
        pointsJson['properties'] as Map<String, dynamic>?;

    final String? forecastHourlyUrl = props?['forecastHourly'] as String?;
    if (forecastHourlyUrl == null || forecastHourlyUrl.isEmpty) {
      throw Exception('NWS forecastHourly URL missing for $lat,$lon');
    }

    // --------------------------------------------------------------
    // 2) Hourly forecast
    // --------------------------------------------------------------
    final forecastUri = Uri.parse(forecastHourlyUrl);
    final forecastResp = await http.get(forecastUri, headers: _headers);

    if (forecastResp.statusCode != 200) {
      throw Exception('NWS hourly forecast ${forecastResp.statusCode}');
    }

    final Map<String, dynamic> forecastJson =
        jsonDecode(forecastResp.body) as Map<String, dynamic>;
    final Map<String, dynamic>? fProps =
        forecastJson['properties'] as Map<String, dynamic>?;
    final List<dynamic>? periods = fProps?['periods'] as List<dynamic>?;

    if (periods == null || periods.isEmpty) {
      throw Exception('NWS hourly forecast periods empty');
    }

    final int n = hours < periods.length ? hours : periods.length;
    double maxGust = 0.0;
    double maxSustained = 0.0;

    for (int i = 0; i < n; i++) {
      final dynamic raw = periods[i];
      if (raw is! Map<String, dynamic>) continue;
      final Map<String, dynamic> p = raw;

      // Typical NWS format: "15 mph" or "".
      final String windSpeedStr = (p['windSpeed'] ?? '').toString();
      final String windGustStr = (p['windGust'] ?? '').toString();

      final double sustained = _parseMph(windSpeedStr);
      final double gust = _parseMph(windGustStr);

      if (sustained > maxSustained) {
        maxSustained = sustained;
      }
      if (gust > maxGust) {
        maxGust = gust;
      }

      // If gust field is empty, fall back on sustained as a proxy.
      if (maxGust == 0 && sustained > 0 && sustained > maxGust) {
        maxGust = sustained;
      }
    }

    if (maxGust <= 0 && maxSustained <= 0) {
      // Explicit failure instead of silently returning "no wind".
      throw Exception('NWS hourly forecast contained no usable wind values');
    }

    return WindSummary(
      maxGustMph: maxGust,
      maxSustainedMph: maxSustained,
    );
  }

  static double _parseMph(String value) {
    if (value.isEmpty) return 0.0;
    final parts = value.split(' ');
    if (parts.isEmpty) return 0.0;
    final double? v = double.tryParse(parts[0]);
    return v ?? 0.0;
  }
}
