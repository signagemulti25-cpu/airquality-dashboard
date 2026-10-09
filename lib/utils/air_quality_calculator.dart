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

AirQualityStatus calculateAirQuality({
  required double aqi,
}) {
  if (aqi <= 50) {
    return const AirQualityStatus(
      title: 'AIR IS GOOD',
      description: 'Minimal impact',
      level: 0,
      gaugeValue: 0.18,
    );
  }

  if (aqi <= 100) {
    return const AirQualityStatus(
      title: 'AIR IS SATISFACTORY',
      description: 'Acceptable air quality',
      level: 1,
      gaugeValue: 0.32,
    );
  }

  if (aqi <= 200) {
    return const AirQualityStatus(
      title: 'AIR IS MODERATE',
      description: 'Some impact possible',
      level: 2,
      gaugeValue: 0.48,
    );
  }

  if (aqi <= 300) {
    return const AirQualityStatus(
      title: 'AIR IS POOR',
      description: 'Health effects possible',
      level: 3,
      gaugeValue: 0.64,
    );
  }

  if (aqi <= 400) {
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