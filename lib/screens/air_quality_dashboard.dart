import 'dart:async';
import 'air_quality_screen.dart';
import 'package:flutter/material.dart';
import '../models/air_quality_data.dart';
import '../services/air_quality_api.dart';
import '../utils/air_quality_calculator.dart';
import 'package:airquality/screens/settings_screen.dart';
import 'package:airquality/utils/air_quality_locations.dart';
import 'package:airquality/models/air_quality_location.dart';
import 'package:airquality/services/location_settings_service.dart';

class AirQualityDashboard extends StatefulWidget {
  const AirQualityDashboard({super.key});

  @override
  State<AirQualityDashboard> createState() => _AirQualityDashboardState();
}

class _AirQualityDashboardState extends State<AirQualityDashboard> {
  final AirQualityApi api = AirQualityApi();

  final Map<String, AirQualityData> locationData = {};

  final Map<String, String> errors = {};

  bool loading = true;
  Timer? refreshTimer;
  final LocationSettingsService settingsService = LocationSettingsService();

  List<AirQualityLocation> locations = [];
  @override
  void initState() {
    super.initState();

    loadLocations();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadAllLocations(),
    );
  }

  Future<void> loadLocations() async {
    final savedLocations = await settingsService.loadLocations();

    if (!mounted) return;

    setState(() {
      locations = savedLocations.isEmpty
          ? List<AirQualityLocation>.from(airQualityLocations)
          : savedLocations;

      // Clear data belonging to old logger IDs
      locationData.clear();
      errors.clear();
    });

    await loadAllLocations();
  }

  Future<void> loadAllLocations() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errors.clear();
    });

    try {
      final allData = await api.fetchAllData();

      if (!mounted) return;

      setState(() {
        locationData
          ..clear()
          ..addAll(allData);

        for (final location in locations) {
          if (!location.enabled) continue;

          if (!allData.containsKey(location.loggerId)) {
            errors[location.loggerId] = 'No reading returned for this logger';
          }
        }

        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;

        for (final location in locations) {
          if (location.enabled) {
            errors[location.loggerId] = error.toString();
          }
        }
      });
    }
  }
  // Future<void> loadAllLocations() async {
  //   if (mounted) {
  //     setState(() {
  //       loading = true;
  //     });
  //   }

  //   await Future.wait(
  //     locations.where((location) => location.enabled).map((location) async {
  //       try {
  //         final data = await api.fetcdata(widget.location.loggerId);

  //         if (!mounted) return;

  //         setState(() {
  //           locationData[location.loggerId] = data;
  //           errors.remove(location.loggerId);
  //         });
  //       } catch (e) {
  //         if (!mounted) return;

  //         setState(() {
  //           errors[location.loggerId] = e.toString();
  //         });
  //       }
  //     }),
  //   );

  //   if (!mounted) return;

  //   setState(() {
  //     loading = false;
  //   });
  // }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int onlineLocations = locationData.values.where((data) {
      final isStale = DateTime.now().difference(data.updatedAt).inMinutes >= 5;

      return !isStale;
    }).length;
    final int offlineLocations = errors.length;
    final int staleLocations = locationData.values.where((data) {
      final difference = DateTime.now().difference(data.updatedAt);

      return difference.inMinutes >= 5;
    }).length;
    final List<double> aqiValues = locationData.values
        .map((data) => data.aqi)
        .toList();

    final double averageAqi = aqiValues.isEmpty
        ? 0
        : aqiValues.reduce((a, b) => a + b) / aqiValues.length;
    final enabledLocations = locations
        .where((location) => location.enabled)
        .toList();
    final int totalLocations = enabledLocations.length;
    return Scaffold(
      backgroundColor: const Color(0xFF07141F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF07141F),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AIR QUALITY MONITORING',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Real-time monitoring dashboard',
              style: TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),

        actions: [
          // --------------------------------
          // REFRESH
          // --------------------------------
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadAllLocations,
            icon: const Icon(Icons.refresh),
          ),

          const SizedBox(width: 4),

          // --------------------------------
          // SETTINGS
          // --------------------------------
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) {
                loadLocations();
              });
            },
            icon: const Icon(Icons.settings),
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          _DashboardSummary(
            totalLocations: totalLocations,

            onlineLocations: onlineLocations,
            staleLocations: staleLocations,
            offlineLocations: offlineLocations,
            averageAqi: averageAqi,
          ),

          Expanded(
            child: Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),

                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),

                itemCount: enabledLocations.length,

                itemBuilder: (context, index) {
                  // IMPORTANT:
                  // Use enabledLocations, NOT locations
                  final location = enabledLocations[index];

                  final data = locationData[location.loggerId];

                  final error = errors[location.loggerId];

                  return _LocationCard(
                    location: location,
                    data: data,
                    error: error,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AirQualityScreen(location: location),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final AirQualityLocation location;

  final AirQualityData? data;

  final String? error;

  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.data,
    required this.error,
    required this.onTap,
  });
  bool _isStale() {
    if (data == null) {
      return false;
    }

    final difference = DateTime.now().difference(data!.updatedAt);

    return difference.inMinutes >= 5;
  }

  @override
  Widget build(BuildContext context) {
    final bool stale = _isStale();

    final bool online = data != null && error == null && !stale;

    final status = data == null ? null : calculateAirQuality(aqi: data!.aqi);

    final Color statusColor = status == null
        ? Colors.grey
        : _getStatusColor(status.level);

    return Material(
      color: const Color(0xFF10232F),

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: const Color(0xFF10232F),

            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: statusColor.withValues(alpha: 0.35),
              width: 2,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),

                blurRadius: 8,

                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ---------------------------
              // LOCATION + ONLINE
              // ---------------------------
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,

                    decoration: BoxDecoration(
                      color: error != null
                          ? Colors.red
                          : stale
                          ? Colors.orange
                          : const Color(0xFF20A83A),
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      location.name,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Text(
                    error != null
                        ? 'OFFLINE'
                        : stale
                        ? 'STALE'
                        : 'ONLINE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: error != null
                          ? Colors.red
                          : stale
                          ? Colors.orange
                          : const Color(0xFF20A83A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (data == null && error == null)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (data == null && error != null)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, color: Colors.red, size: 28),
                        SizedBox(height: 6),
                        Text(
                          'Data unavailable',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      // ---------------------------
                      // AQI
                      // ---------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        crossAxisAlignment: CrossAxisAlignment.end,

                        children: [
                          Text(
                            data!.aqi.toStringAsFixed(0),

                            style: TextStyle(
                              fontSize: 34,

                              fontWeight: FontWeight.w800,

                              color: statusColor,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),

                            child: Text(
                              'AQI',

                              style: TextStyle(
                                fontSize: 10,

                                fontWeight: FontWeight.w600,

                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Text(
                        status?.title ?? 'UNKNOWN',

                        style: TextStyle(
                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: statusColor,
                        ),
                      ),

                      const SizedBox(height: 8),
                      _AqiLevelBar(level: status?.level ?? 0),
                      const SizedBox(height: 8),
                      // ---------------------------
                      // PM VALUES
                      // ---------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          _Value(label: 'PM2.5', value: data!.pm25),

                          const SizedBox(width: 18),

                          _Value(label: 'PM10', value: data!.pm10),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 5),

              // ---------------------------
              // LOGGER ID
              // ---------------------------
              Row(
                children: [
                  Text(
                    'Logger: ${location.loggerId}',
                    style: const TextStyle(fontSize: 9, color: Colors.white54),
                  ),

                  const Spacer(),

                  if (data != null)
                    Text(
                      _formatUpdatedTime(data!.updatedAt),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white54,
                      ),
                    ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 9,
                    color: Colors.white38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUpdatedTime(DateTime time) {
    final localTime = time.toLocal();

    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;

    final minute = localTime.minute.toString().padLeft(2, '0');

    final second = localTime.second.toString().padLeft(2, '0');

    final period = localTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute:$second $period';
  }

  Color _getStatusColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF00A651); // GOOD

      case 1:
        return const Color(0xFF8BC34A); // SATISFACTORY

      case 2:
        return const Color(0xFFFFC107); // MODERATE

      case 3:
        return const Color(0xFFFF9800); // POOR

      case 4:
        return const Color(0xFFF44336); // VERY POOR

      case 5:
        return const Color(0xFF8B0000); // SEVERE

      default:
        return Colors.grey;
    }
  }
}

class _Value extends StatelessWidget {
  final String label;
  final double value;

  const _Value({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),

        const SizedBox(width: 4),

        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AqiLevelBar extends StatelessWidget {
  final int level;

  const _AqiLevelBar({required this.level});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF00A651),
      Color(0xFF8BC34A),
      Color(0xFFFFC107),
      Color(0xFFFF9800),
      Color(0xFFF44336),
      Color(0xFF8B0000),
    ];

    return Row(
      children: List.generate(colors.length, (index) {
        final bool active = index <= level;

        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
            decoration: BoxDecoration(
              color: active ? colors[index] : Colors.white12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  final int totalLocations;
  final int onlineLocations;
  final int staleLocations;
  final int offlineLocations;
  final double averageAqi;

  const _DashboardSummary({
    required this.totalLocations,
    required this.onlineLocations,
    required this.staleLocations,
    required this.offlineLocations,
    required this.averageAqi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3DF)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'LOCATIONS',
            value: '$totalLocations',
            color: const Color(0xFF202420),
          ),

          _SummaryItem(
            label: 'ONLINE',
            value: '$onlineLocations',
            color: const Color(0xFF20A83A),
          ),
          _SummaryItem(
            label: 'STALE',
            value: '$staleLocations',
            color: Colors.orange,
          ),
          _SummaryItem(
            label: 'OFFLINE',
            value: '$offlineLocations',
            color: Colors.red,
          ),

          _SummaryItem(
            label: 'AVERAGE AQI',
            value: averageAqi.toStringAsFixed(0),
            color: _getAqiColor(averageAqi),
          ),
        ],
      ),
    );
  }

  Color _getAqiColor(double aqi) {
    final status = calculateAirQuality(aqi: aqi);

    switch (status.level) {
      case 0:
        return const Color(0xFF00A651);
      case 1:
        return const Color(0xFF8BC34A);
      case 2:
        return const Color(0xFFFFC107);
      case 3:
        return const Color(0xFFFF9800);
      case 4:
        return const Color(0xFFF44336);
      case 5:
        return const Color(0xFF8B0000);
      default:
        return Colors.grey;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
