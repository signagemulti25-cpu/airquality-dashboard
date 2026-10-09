import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;
import '../models/air_quality_data.dart';
import '../models/air_quality_data.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/air_quality_data.dart';

// class AirQualityApi {

//   static const String baseUrl =
//       'https://dataloggersindia.org/api/logger_log/848';

//   Future<AirQualityData> fetchData() async {

//     final response = await http.get(
//       Uri.parse(baseUrl),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(
//         'Server error: ${response.statusCode}',
//       );
//     }

//     final decoded =
//         jsonDecode(response.body);

//     if (decoded['status']?.toString() != '200') {
//       throw Exception(
//         decoded['message']?.toString() ??
//             'Unable to fetch air quality data',
//       );
//     }

//     final data =
//         decoded['data'] as Map<String, dynamic>;

//     return AirQualityData.fromJson(data);
//   }
// }

class AirQualityApi {
  static const String baseUrl =
      'https://lingering-block-aa0f.signagemulti25.workers.dev';

  Future<Map<String, AirQualityData>> fetchAllData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/all'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Proxy error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    final rawData = decoded['data'] as Map<String, dynamic>;
    final result = <String, AirQualityData>{};

    for (final entry in rawData.entries) {
      final item = entry.value as Map<String, dynamic>;

      if (item['ok'] == true && item['data'] is Map) {
        final data = Map<String, dynamic>.from(item['data'] as Map);
        result[entry.key] = AirQualityData.fromJson(data);
      }
    }

    return result;
  }
}
// class AirQualityApi {

//   Future<AirQualityData> fetchData(String loggerId) async {

//     final url =
//         'https://dataloggersindia.org/api/logger_log/$loggerId';

//     final response = await http.get(
//       Uri.parse(url),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(
//         'Server error: ${response.statusCode}',
//       );
//     }

//     final decoded = jsonDecode(response.body);

//     if (decoded['status']?.toString() != '200') {
//       throw Exception(
//         decoded['message']?.toString() ??
//             'Unable to fetch air quality data',
//       );
//     }

//     final data =
//         decoded['data'] as Map<String, dynamic>;

//     return AirQualityData.fromJson(data);
//   }
// }
