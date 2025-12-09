/* lib/api.dart */
import "dart:convert"; // Keep this since we're decoding JSON
import "package:http/http.dart" as http;
import "config.dart";

const String apiBasePrimary =
    "https://da-wx-backend-1.onrender.com"
    "/api/v1";


Future<http.Response> _getWithFailover(Uri Function(String base) makeUri, {Duration timeout = const Duration(seconds: 60)}) async {
  final bases = <String>[apiBasePrimary, ...apiBaseAlternates];
  Object? lastError;

  for (final base in bases) {
    try {
      final uri = makeUri(base);
      final resp = await http.get(uri).timeout(timeout);
      return resp; // Always returns a response or throws an exception
    } catch (e) {
      lastError = e;
    }
  }

  // If we exit the loop, it means all attempts failed, so we throw an exception
  throw Exception("All bases failed: $lastError");
}

Future<List<dynamic>> fetchStateReport({String state = "TX", int hours = 36, String metric = "wind", double threshold = 22}) async {
  http.Response resp = await _getWithFailover((base) =>
      Uri.parse("$base/report/state?state=$state&hours=$hours&metric=$metric&threshold=$threshold"));

  if (resp.statusCode == 200) {
    final data = json.decode(resp.body);
    if (data is List) return data;
    return const [];
  } else {
    throw Exception("HTTP ${resp.statusCode}: ${resp.body}");
  }
}

Future<List<dynamic>> fetchNationalReport({int hours = 36, String metric = "wind", double threshold = 22, String? statesCsv, int capPerState = 60}) async {
  final qp = <String, String>{
    "hours": "$hours",
    "metric": metric,
    "threshold": "$threshold",
    "cap_per_state": "$capPerState",
  };
  if (statesCsv != null && statesCsv.trim().isNotEmpty) {
    qp["states"] = statesCsv;
  }

  http.Response resp = await _getWithFailover((base) {
    final b = StringBuffer("$base/report/national?");
    bool first = true;
    qp.forEach((k, v) {
      if (!first) { b.write("&"); } else { first = false; }
      b.write("$k=$v");
    });
    return Uri.parse(b.toString());
  });

  if (resp.statusCode == 200) {
    final data = json.decode(resp.body);
    if (data is List) return data;
    return const [];
  } else {
    throw Exception("HTTP ${resp.statusCode}: ${resp.body}");
  }
}

