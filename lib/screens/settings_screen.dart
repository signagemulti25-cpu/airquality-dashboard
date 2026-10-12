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
  bool saving = false;
  String? error;

  // Stored only in memory; never saved in the app's source or preferences.
  String? _adminToken;

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      final saved = await settingsService.loadLocations();

      if (!mounted) return;

      setState(() {
        locations = saved.isEmpty
            ? List<AirQualityLocation>.from(airQualityLocations)
            : saved;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Could not load shared settings: $e';
      });
    }
  }

  Future<String?> _getAdminToken() async {
    if (_adminToken != null && _adminToken!.isNotEmpty) {
      return _adminToken;
    }

    final controller = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Administrator authorization'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Admin token',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (token == null || token.isEmpty) return null;

    _adminToken = token;
    return token;
  }

  Future<bool> _saveSharedLocations(List<AirQualityLocation> updated) async {
    final token = await _getAdminToken();

    if (token == null) return false;
    if (!mounted) return false;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await settingsService.saveLocations(updated, adminToken: token);

      if (!mounted) return true;

      setState(() {
        locations = List<AirQualityLocation>.from(updated);
        saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shared settings saved')));

      return true;
    } catch (e) {
      if (!mounted) return false;

      // Forget an invalid token so it can be entered again.
      if (e.toString().contains('401')) {
        _adminToken = null;
      }

      setState(() {
        saving = false;
        error = 'Could not save shared settings: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));

      return false;
    }
  }

  Future<void> toggleLocation(int index, bool enabled) async {
    if (saving) return;

    final previous = List<AirQualityLocation>.from(locations);

    final updated = List<AirQualityLocation>.from(locations);
    updated[index] = updated[index].copyWith(enabled: enabled);

    // Show the change immediately; restore it if saving fails.
    setState(() {
      locations = updated;
    });

    final success = await _saveSharedLocations(updated);

    if (!success && mounted) {
      setState(() {
        locations = previous;
      });
    }
  }

  Future<void> editLocation(int index) async {
    if (saving) return;

    final location = locations[index];
    final nameController = TextEditingController(text: location.name);
    final loggerController = TextEditingController(text: location.loggerId);

    final result = await showDialog<AirQualityLocation>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final id = loggerController.text.trim();

              if (name.isEmpty || id.isEmpty) return;

              Navigator.pop(
                dialogContext,
                AirQualityLocation(
                  name: name,
                  loggerId: id,
                  enabled: location.enabled,
                ),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    nameController.dispose();
    loggerController.dispose();

    if (result == null || !mounted) return;

    // Preserve the existing enabled/disabled state.
    final updated = List<AirQualityLocation>.from(locations);
    updated[index] = result;

    await _saveSharedLocations(updated);
  }

  Future<void> resetLocations() async {
    if (saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Locations?'),
        content: const Text(
          'Restore the default location names, logger IDs, '
          'and enable all locations for everyone?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final defaults = airQualityLocations
        .map((location) => location.copyWith(enabled: true))
        .toList();

    await _saveSharedLocations(defaults);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07141F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07141F),
        foregroundColor: Colors.white,
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset locations',
            icon: const Icon(Icons.restore),
            onPressed: saving ? null : resetLocations,
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
                    'Changes apply to everyone using the dashboard.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  if (saving) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    TextButton(
                      onPressed: loadLocations,
                      child: const Text('Retry loading'),
                    ),
                  ],
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
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                            ),
                            title: Text(
                              location.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Logger ID: ${location.loggerId}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: location.enabled,
                                  onChanged: saving
                                      ? null
                                      : (value) => toggleLocation(index, value),
                                ),
                                IconButton(
                                  tooltip: 'Edit location',
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                  ),
                                  onPressed: saving
                                      ? null
                                      : () => editLocation(index),
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
