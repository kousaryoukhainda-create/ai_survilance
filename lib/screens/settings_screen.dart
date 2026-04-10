import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movement_provider.dart';
import 'known_persons_screen.dart';
import 'storage_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MovementProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              // Notification Section
              _buildSectionHeader(context, Icons.notifications_active, 'Notifications'),

              _buildSwitchTile(
                context,
                icon: Icons.notifications,
                title: 'System Notifications',
                subtitle: 'Show notifications in system tray',
                value: provider.enableSystemNotification,
                onChanged: (value) {
                  provider.updateNotificationSettings(
                    enableSystemNotification: value,
                  );
                },
              ),

              _buildSwitchTile(
                context,
                icon: Icons.volume_up,
                title: 'Sound Alerts',
                subtitle: 'Play sound when movement detected',
                value: provider.enableSound,
                onChanged: (value) {
                  provider.updateNotificationSettings(enableSound: value);
                },
              ),

              _buildSwitchTile(
                context,
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Vibrate device on detection',
                value: provider.enableVibration,
                onChanged: (value) {
                  provider.updateNotificationSettings(enableVibration: value);
                },
              ),

              _buildSwitchTile(
                context,
                icon: Icons.sticky_note_2,
                title: 'Persistent Notification',
                subtitle: 'Show "Monitoring Active" notification',
                value: provider.enablePersistentNotification,
                onChanged: (value) {
                  provider.updateNotificationSettings(
                    enablePersistentNotification: value,
                  );
                },
              ),

              const Divider(height: 32),

              // Detection Settings Section
              _buildSectionHeader(context, Icons.tune, 'Detection Settings'),

              // Motion Threshold Slider
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Text(
                            'Motion Sensitivity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Threshold: ${provider.motionThreshold.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getSensitivityColor(provider.motionThreshold),
                        ),
                      ),
                      Text(
                        _getSensitivityLabel(provider.motionThreshold),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Slider(
                        value: provider.motionThreshold,
                        min: 5,
                        max: 80,
                        divisions: 75,
                        label: '${provider.motionThreshold.toStringAsFixed(0)}%',
                        onChanged: (value) {
                          provider.updateDetectionThresholds(motionThreshold: value);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sensitive', style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text('Strict', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Pixel Difference Threshold
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.compare, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Text(
                            'Pixel Difference Threshold',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Value: ${provider.pixelDifferenceThreshold.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: provider.pixelDifferenceThreshold,
                        min: 5,
                        max: 100,
                        divisions: 95,
                        label: provider.pixelDifferenceThreshold.toStringAsFixed(0),
                        onChanged: (value) {
                          provider.updateDetectionThresholds(
                            pixelDifferenceThreshold: value,
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sensitive', style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text('Strict', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Live Detection Boxes
              _buildSwitchTile(
                context,
                icon: Icons.crop_square,
                title: 'Live Detection Boxes',
                subtitle: 'Show AI detection boxes on camera preview',
                value: provider.enableLiveDetectionBoxes,
                onChanged: (value) {
                  provider.setLiveDetectionBoxes(value);
                },
              ),

              const Divider(height: 32),

              // Schedule Section
              _buildSectionHeader(context, Icons.schedule, 'Monitoring Schedule'),

              // Schedule toggle
              _buildSwitchTile(
                context,
                icon: Icons.access_time,
                title: 'Scheduled Monitoring',
                subtitle: provider.scheduleService.scheduleEnabled
                    ? provider.scheduleService.scheduleSummary
                    : 'Monitoring always active',
                value: provider.scheduleService.scheduleEnabled,
                onChanged: (value) async {
                  await provider.scheduleService.setScheduleEnabled(value);
                  if (mounted) setState(() {});
                },
              ),

              // Schedule time picker
              if (provider.scheduleService.scheduleEnabled)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.timer, color: Colors.blue.shade700),
                    title: const Text('Monitoring Hours'),
                    subtitle: Text(
                      '${_formatTimeOfDay(provider.scheduleService.startTime)} - ${_formatTimeOfDay(provider.scheduleService.endTime)}',
                    ),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () => _showSchedulePicker(context, provider),
                  ),
                ),

              // Quiet Hours
              _buildSwitchTile(
                context,
                icon: Icons.do_not_disturb,
                title: 'Quiet Hours',
                subtitle: provider.scheduleService.quietHoursEnabled
                    ? provider.scheduleService.quietHoursSummary
                    : 'Notifications always active',
                value: provider.scheduleService.quietHoursEnabled,
                onChanged: (value) async {
                  await provider.scheduleService.setQuietHoursEnabled(value);
                  if (mounted) setState(() {});
                },
              ),

              if (provider.scheduleService.quietHoursEnabled)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.nightlight, color: Colors.indigo.shade700),
                    title: const Text('Quiet Hours'),
                    subtitle: Text(
                      '${_formatTimeOfDay(provider.scheduleService.quietStart)} - ${_formatTimeOfDay(provider.scheduleService.quietEnd)}',
                    ),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () => _showQuietHoursPicker(context, provider),
                  ),
                ),

              const Divider(height: 32),

              // Identification Section
              _buildSectionHeader(context, Icons.face, 'Person Identification'),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.people, color: Colors.purple),
                  title: const Text('Known Persons'),
                  subtitle: const Text('Manage registered faces'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KnownPersonsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 32),

              // Storage Section
              _buildSectionHeader(context, Icons.storage, 'Storage'),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.folder_open, color: Colors.teal),
                  title: const Text('Storage Management'),
                  subtitle: provider.storageInfo != null
                      ? Text('${provider.storageInfo!.totalFormatted} used')
                      : const Text('View storage usage and cleanup'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StorageManagementScreen(),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 32),

              // Reset button
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.updateNotificationSettings(
                      enableSystemNotification: true,
                      enableSound: true,
                      enableVibration: true,
                      enablePersistentNotification: true,
                    );
                    provider.updateDetectionThresholds(
                      motionThreshold: 30.0,
                      pixelDifferenceThreshold: 25.0,
                    );
                    provider.setLiveDetectionBoxes(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings reset to defaults')),
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getSensitivityColor(double threshold) {
    if (threshold < 20) return Colors.green;
    if (threshold < 40) return Colors.blue;
    if (threshold < 60) return Colors.orange;
    return Colors.red;
  }

  String _getSensitivityLabel(double threshold) {
    if (threshold < 20) return 'Very Sensitive - detects small movements';
    if (threshold < 40) return 'Sensitive - detects moderate movements';
    if (threshold < 60) return 'Normal - balanced detection';
    return 'Strict - only large movements';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _showSchedulePicker(
    BuildContext context,
    MovementProvider provider,
  ) async {
    TimeOfDay start = provider.scheduleService.startTime;
    TimeOfDay end = provider.scheduleService.endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Monitoring Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Start Time'),
                trailing: Text(_formatTimeOfDay(start)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (time != null) {
                    setState(() => start = time);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.stop),
                title: const Text('End Time'),
                trailing: Text(_formatTimeOfDay(end)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (time != null) {
                    setState(() => end = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await provider.scheduleService.setStartTime(start);
                await provider.scheduleService.setEndTime(end);
                if (!context.mounted) return;
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuietHoursPicker(
    BuildContext context,
    MovementProvider provider,
  ) async {
    TimeOfDay start = provider.scheduleService.quietStart;
    TimeOfDay end = provider.scheduleService.quietEnd;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Quiet Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notifications will be suppressed during these hours',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.nightlight),
                title: const Text('Start Time'),
                trailing: Text(_formatTimeOfDay(start)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (time != null) {
                    setState(() => start = time);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('End Time'),
                trailing: Text(_formatTimeOfDay(end)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (time != null) {
                    setState(() => end = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await provider.scheduleService.setQuietStart(start);
                await provider.scheduleService.setQuietEnd(end);
                if (!context.mounted) return;
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
