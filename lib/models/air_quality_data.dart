class AirQualityData {
  final String loggerId;
  final double pm25;
  final double pm10;
  final double aqi;
  final DateTime updatedAt;

  AirQualityData({
    required this.loggerId,
    required this.pm25,
    required this.pm10,
    required this.aqi,
    required this.updatedAt,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    return AirQualityData(
      loggerId: json['logger_id']?.toString() ?? '',

      // ch1 = PM2.5
      pm25: double.tryParse(json['ch1']?.toString() ?? '') ?? 0,

      // ch2 = PM10
      pm10: double.tryParse(json['ch2']?.toString() ?? '') ?? 0,

      // ch3 = AQI
      aqi: double.tryParse(json['ch3']?.toString() ?? '') ?? 0,

      updatedAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
