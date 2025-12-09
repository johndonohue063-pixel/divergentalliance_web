class WxReportRow {
  final String state;
  final String county;
  final int severity;

  /// 0.0–1.0 confidence value
  final double probability;

  /// Expected gust speed (mph)
  final double expectedGust;

  /// Expected sustained wind (mph)
  final double expectedSustained;

  /// Max observed / modeled gust (mph)
  final double maxGust;

  /// Max observed / modeled sustained wind (mph)
  final double maxSustained;

  /// Recommended crew count
  final int crews;

  const WxReportRow({
    required this.state,
    required this.county,
    required this.severity,
    required this.probability,
    required this.expectedGust,
    required this.expectedSustained,
    required this.maxGust,
    required this.maxSustained,
    required this.crews,
  });

  factory WxReportRow.fromJson(Map<String, dynamic> json) {
    double _asDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return WxReportRow(
      state: json['state']?.toString() ?? '',
      county: json['county']?.toString() ?? '',
      severity: _asInt(json['severity']),
      probability: _asDouble(json['probability']),
      expectedGust: _asDouble(json['expectedGust']),
      expectedSustained: _asDouble(json['expectedSustained']),
      maxGust: _asDouble(json['maxGust']),
      maxSustained: _asDouble(json['maxSustained']),
      crews: _asInt(json['crews']),
    );
  }

  Map<String, dynamic> toJson() => {
        'state': state,
        'county': county,
        'severity': severity,
        'probability': probability,
        'expectedGust': expectedGust,
        'expectedSustained': expectedSustained,
        'maxGust': maxGust,
        'maxSustained': maxSustained,
        'crews': crews,
      };
}
