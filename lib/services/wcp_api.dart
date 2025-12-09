import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WcpRegion {
  final String id, name, state;
  final double? gust, sustained;
  final int severity;
  final int? crewRec;

  WcpRegion({
    required this.id,
    required this.name,
    required this.state,
    this.gust,
    this.sustained,
    required this.severity,
    this.crewRec,
  });

  factory WcpRegion.fromJson(Map<String, dynamic> j) => WcpRegion(
    id: j['region_id'] as String,
    name: j['region_name'] as String,
    state: (j['state'] ?? '') as String,
    gust: (j['expected_gust_mph'] as num?)?.toDouble(),
    sustained: (j['expected_sustained_mph'] as num?)?.toDouble(),
    severity: (j['severity'] ?? 0) as int,
    crewRec: (j['crew_rec'] as num?)?.toInt(),
  );
}

class WcpApi {
  final String base;
  WcpApi([String? fallback])
      : base = (const String.fromEnvironment('WX_BACKEND_URL', defaultValue: '')).isNotEmpty
          ? const String.fromEnvironment('WX_BACKEND_URL', defaultValue: '')
          : (fallback ?? 'https://da-wx-backend-1.onrender.com
  WcpApi(this.base);

  Future<List<WcpRegion>> reportRegions({
    required int hours,
    required String metric, // 'gust' | 'sustained'
    required int threshold,
    int minSev = 0,
    String scope = 'nationwide',
    String? state,
  }) async {
    final qp = <String, String>{
      'hours': '$hours',
      'metric': metric,
      'threshold': '$threshold',
      'min_sev': '$minSev',
      'scope': scope,
      if (state != null) 'state': state,
    };

    final uri = Uri.parse('$base/report/regions').replace(queryParameters: qp);

    final res = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'DivergentAlliance-WCP/1.0',
          },
        )
        .timeout(const Duration(seconds: 90));

    if (res.statusCode != 200) {
      throw Exception('WCP ${res.statusCode}: ${res.body}');
    }

    final Map<String, dynamic> j = json.decode(res.body) as Map<String, dynamic>;
    final List<Map<String, dynamic>> rows =
        (j['regions'] as List).cast<Map<String, dynamic>>();
    return rows.map(WcpRegion.fromJson).toList(growable: false);
  }
}

