class WeatherReport {
  final double windSpeed;       // mph
  final double gustSpeed;       // mph
  final double precipitation;   // in/hr
  final double pressure;        // mb or hPa
  final double outageRisk;      // 0–100
  final double temp;            // F
  final double lightningRate;   // strikes/hr

  WeatherReport({
    required this.windSpeed,
    required this.gustSpeed,
    required this.precipitation,
    required this.pressure,
    required this.outageRisk,
    required this.temp,
    required this.lightningRate,
  });

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    return WeatherReport(
      windSpeed:      (json['windSpeed']      as num).toDouble(),
      gustSpeed:      (json['gustSpeed']      as num).toDouble(),
      precipitation:  (json['precipitation']  as num).toDouble(),
      pressure:       (json['pressure']       as num).toDouble(),
      outageRisk:     (json['outageRisk']     as num).toDouble(),
      temp:           (json['temperature']    as num).toDouble(),
      lightningRate:  (json['lightningRate']  as num).toDouble(),
    );
  }
}
