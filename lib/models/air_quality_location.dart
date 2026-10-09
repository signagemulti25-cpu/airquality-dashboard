class AirQualityLocation {
  final String name;
  final String loggerId;
  final bool enabled;

  const AirQualityLocation({
    required this.name,
    required this.loggerId,
    this.enabled = true,
  });

  AirQualityLocation copyWith({
    String? name,
    String? loggerId,
    bool? enabled,
  }) {
    return AirQualityLocation(
      name: name ?? this.name,
      loggerId: loggerId ?? this.loggerId,
      enabled: enabled ?? this.enabled,
    );
  }
}