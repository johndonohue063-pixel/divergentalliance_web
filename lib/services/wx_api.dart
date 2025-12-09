// lib/services/wx_api.dart
//
// Legacy placeholder now that Open‑Meteo is no longer used on the client.
// WxPro and Weather Center screens should rely on WxService (NWS) or
// WxBackendService (da-wx-backend-1.onrender.com) instead.

class WxApiWind {
  final double maxGustMph;
  final double maxSustainedMph;
  final DateTime windowStart;
  final DateTime windowEnd;

  const WxApiWind({
    required this.maxGustMph,
    required this.maxSustainedMph,
    required this.windowStart,
    required this.windowEnd,
  });
}

class WxApi {
  const WxApi._();

  /// This exists only so older code can compile. New code should not call this.
  static Future<WxApiWind> fetchWind({
    required double lat,
    required double lon,
    required int windowHours,
  }) async {
    throw UnsupportedError(
      'WxApi.fetchWind is deprecated. Use WxService/WxBackendService instead.',
    );
  }
}
