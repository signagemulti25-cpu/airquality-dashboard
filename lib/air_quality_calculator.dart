import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:airquality/models/air_quality_data.dart';




class AirQualityApi {
  final String baseUrl;

  const AirQualityApi({required this.baseUrl});

  Future<AirQualityData> fetch() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Air quality API returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid air quality response');
    }

    return AirQualityData.fromJson(json);
  }
}
