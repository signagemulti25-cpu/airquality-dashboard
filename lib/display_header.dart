class AirQualityStatus {
  final String title;
  final String description;
  final int level;
  final double gaugeValue;

  const AirQualityStatus({
    required this.title,
    required this.description,
    required this.level,
    required this.gaugeValue,
  });
}

// Display categories can be adjusted later to the exact AQI/standard used by the cloud.
AirQualityStatus calculateAirQuality({required double pm25, required double pm10}) {
  final value = pm25 > 0 ? pm25 : pm10;

  if (value <= 30) {
    return const AirQualityStatus(
      title: 'AIR IS GOOD',
      description: 'Minimal impact',
      level: 0,
      gaugeValue: 0.18,
    );
  }
  if (value <= 60) {
    return const AirQualityStatus(
      title: 'AIR IS SATISFACTORY',
      description: 'Acceptable air quality',
      level: 1,
      gaugeValue: 0.32,
    );
  }
  if (value <= 90) {
    return const AirQualityStatus(
      title: 'AIR IS MODERATE',
      description: 'Some impact possible',
      level: 2,
      gaugeValue: 0.48,
    );
  }
  if (value <= 120) {
    return const AirQualityStatus(
      title: 'AIR IS POOR',
      description: 'Health effects possible',
      level: 3,
      gaugeValue: 0.64,
    );
  }
  if (value <= 250) {
    return const AirQualityStatus(
      title: 'AIR IS VERY POOR',
      description: 'Health alert',
      level: 4,
      gaugeValue: 0.80,
    );
  }
  return const AirQualityStatus(
    title: 'AIR IS SEVERE',
    description: 'Health emergency conditions',
    level: 5,
    gaugeValue: 0.96,
  );
}
