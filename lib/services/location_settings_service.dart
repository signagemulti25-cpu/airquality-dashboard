import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_location.dart';




class LocationSettingsService {
  static const String _baseUrl =
      'https://lingering-block-aa0f.signagemulti25.workers.dev';

  Future<List<AirQualityLocation>> loadLocations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/settings'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load shared settings: ${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    final saved = decoded['locations'] as List<dynamic>? ?? [];

    return saved.map((item) {
      final location = Map<String, dynamic>.from(item as Map);

      return AirQualityLocation(
        name: location['name']?.toString() ?? '',
        loggerId: location['loggerId']?.toString() ?? '',
        enabled: location['enabled'] == true,
      );
    }).toList();
  }

  Future<void> saveLocations(
    List<AirQualityLocation> locations, {
    required String adminToken,
  }) async {
    final data = locations.map((location) {
      return {
        'name': location.name,
        'loggerId': location.loggerId,
        'enabled': location.enabled,
      };
    }).toList();

    final response = await http.put(
      Uri.parse('$_baseUrl/api/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $adminToken',
      },
      body: jsonEncode({'locations': data}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to save shared settings: '
        '${response.statusCode} ${response.body}',
      );
    }
  }
}
