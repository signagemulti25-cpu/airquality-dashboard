import 'dart:convert';
import '../models/air_quality_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSettingsService {
  static const String _locationsKey = 'air_quality_locations';

  Future<List<AirQualityLocation>> loadLocations() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_locationsKey);

    if (saved == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(saved);

    return decoded.map((item) {
      return AirQualityLocation(
        name: item['name']?.toString() ?? '',
        loggerId: item['loggerId']?.toString() ?? '',
        enabled: item['enabled'] == null ? true : item['enabled'] == true,
      );
    }).toList();
  }

  Future<void> saveLocations(List<AirQualityLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();

    final data = locations.map((location) {
      return {
        'name': location.name,
        'loggerId': location.loggerId,
        'enabled': location.enabled,
      };
    }).toList();

    await prefs.setString(_locationsKey, jsonEncode(data));
  }
}
