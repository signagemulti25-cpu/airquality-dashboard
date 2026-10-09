import 'package:flutter/material.dart';
import '../models/air_quality_location.dart';
import '../services/location_settings_service.dart';
import 'package:airquality/utils/air_quality_locations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocationSettingsService settingsService = LocationSettingsService();

  List<AirQualityLocation> locations = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    final savedLocations = await settingsService.loadLocations();

    if (!mounted) return;

    setState(() {
      locations = savedLocations.isEmpty
          ? List<AirQualityLocation>.from(airQualityLocations)
          : savedLocations;

      loading = false;
    });
  }

  Future<void> editLocation(int index) async {
    final location = locations[index];

    final nameController = TextEditingController(text: location.name);

    final loggerController = TextEditingController(text: location.loggerId);

    final result = await showDialog<AirQualityLocation>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Location'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: loggerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Logger ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();

                final loggerId = loggerController.text.trim();

                if (name.isEmpty || loggerId.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  AirQualityLocation(name: name, loggerId: loggerId),
                );
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    loggerController.dispose();

    if (result == null) return;

    setState(() {
      locations[index] = result;
    });

    await settingsService.saveLocations(locations);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location settings saved')));
  }

  Future<void> resetLocations() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Locations?'),
          content: const Text(
            'This will restore all location names '
            'and logger IDs to the default configuration.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await settingsService.saveLocations(airQualityLocations);

    if (!mounted) return;

    setState(() {
      locations = List<AirQualityLocation>.from(airQualityLocations);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Locations restored to default')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07141F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF07141F),
        foregroundColor: Colors.white,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'SETTINGS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        actions: [
          IconButton(
            tooltip: 'Reset locations',
            icon: const Icon(Icons.restore),
            onPressed: resetLocations,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Location Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Change location names and logger IDs',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: ListView.builder(
                      itemCount: locations.length,

                      itemBuilder: (context, index) {
                        final location = locations[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),

                          decoration: BoxDecoration(
                            color: const Color(0xFF10232F),

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: Colors.white12),
                          ),

                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),

                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.green,
                              ),
                            ),

                            title: Text(
                              location.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Logger ID: ${location.loggerId}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: location.enabled,
                                  onChanged: (value) async {
                                    setState(() {
                                      locations[index] = location.copyWith(
                                        enabled: value,
                                      );
                                    });

                                    await settingsService.saveLocations(
                                      locations,
                                    );
                                  },
                                ),

                                IconButton(
                                  tooltip: 'Edit location',
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    editLocation(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
