import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movement_provider.dart';
import '../services/whatsapp_service.dart';
import '../services/google_sheets_service.dart';
import 'known_persons_screen.dart';
import 'storage_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WhatsAppService _whatsappService = WhatsAppService.instance;
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService.instance;
  bool _isWhatsAppInitialized = false;
  bool _isGoogleSheetsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _whatsappService.initialize();
    await _googleSheetsService.initialize();
    if (mounted) {
      setState(() {
        _isWhatsAppInitialized = true;
        _isGoogleSheetsInitialized = true;
      });
    }
  }
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

              // Google Sheets Integration Section
              if (_isGoogleSheetsInitialized) ...[
                _buildSectionHeader(context, Icons.table_chart, 'Google Sheets Auto-Log'),

                _buildSwitchTile(
                  context,
                  icon: Icons.cloud_upload,
                  title: 'Auto-Upload to Google Sheets',
                  subtitle: _googleSheetsService.isConfigured
                      ? 'Fully automatic - no interaction needed'
                      : 'Configure webhook URL to enable',
                  value: _googleSheetsService.isEnabled,
                  onChanged: (value) async {
                    await _googleSheetsService.updateSettings(enabled: value);
                    if (mounted) setState(() {});
                  },
                ),

                if (_googleSheetsService.isEnabled)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.link, color: Colors.blue.shade700),
                      title: const Text('Webhook URL'),
                      subtitle: Text(
                        _googleSheetsService.webhookUrl.isNotEmpty
                            ? '✓ Configured'
                            : 'Tap to configure',
                      ),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () => _showGoogleSheetsUrlDialog(context),
                    ),
                  ),

                if (_googleSheetsService.isEnabled && _googleSheetsService.webhookUrl.isNotEmpty) ...[
                  _buildSwitchTile(
                    context,
                    icon: Icons.image,
                    title: 'Upload Snapshots',
                    subtitle: 'Automatically upload snapshot images to Google Drive',
                    value: _googleSheetsService.uploadImages,
                    onChanged: (value) async {
                      await _googleSheetsService.updateSettings(uploadImages: value);
                      if (mounted) setState(() {});
                    },
                  ),

                  _buildSwitchTile(
                    context,
                    icon: Icons.videocam,
                    title: 'Upload Videos',
                    subtitle: 'Upload videos (max 10MB per video)',
                    value: _googleSheetsService.uploadVideos,
                    onChanged: (value) async {
                      await _googleSheetsService.updateSettings(uploadVideos: value);
                      if (mounted) setState(() {});
                    },
                  ),

                  // Test webhook button
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green.shade700),
                      title: const Text('Test Connection'),
                      subtitle: const Text('Verify webhook URL is working'),
                      trailing: ElevatedButton(
                        onPressed: () => _testGoogleSheetsWebhook(context),
                        child: const Text('Test'),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 32),
              ],

              // WhatsApp Integration Section
              if (_isWhatsAppInitialized) ...[
                _buildSectionHeader(context, Icons.message, 'WhatsApp Integration'),

                _buildSwitchTile(
                  context,
                  icon: Icons.share,
                  title: 'Auto-Share to WhatsApp',
                  subtitle: _whatsappService.isConfigured
                      ? 'Sending to: ${_whatsappService.phoneNumber}'
                      : 'Configure WhatsApp number to enable',
                  value: _whatsappService.isEnabled,
                  onChanged: (value) async {
                    await _whatsappService.updateSettings(enabled: value);
                    if (mounted) setState(() {});
                  },
                ),

                if (_whatsappService.isEnabled)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.phone, color: Colors.green.shade700),
                      title: const Text('WhatsApp Number'),
                      subtitle: Text(
                        _whatsappService.phoneNumber.isNotEmpty
                            ? _whatsappService.phoneNumber
                            : 'Tap to configure',
                      ),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () => _showWhatsAppPhoneDialog(context),
                    ),
                  ),

                if (_whatsappService.isEnabled && _whatsappService.phoneNumber.isNotEmpty) ...[
                  _buildSwitchTile(
                    context,
                    icon: Icons.image,
                    title: 'Share Snapshots',
                    subtitle: 'Include snapshot images in WhatsApp messages',
                    value: _whatsappService.shareSnapshots,
                    onChanged: (value) async {
                      await _whatsappService.updateSettings(shareSnapshots: value);
                      if (mounted) setState(() {});
                    },
                  ),

                  _buildSwitchTile(
                    context,
                    icon: Icons.videocam,
                    title: 'Share Videos',
                    subtitle: 'Include video recordings in WhatsApp messages',
                    value: _whatsappService.shareVideos,
                    onChanged: (value) async {
                      await _whatsappService.updateSettings(shareVideos: value);
                      if (mounted) setState(() {});
                    },
                  ),

                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.edit_note, color: Colors.blue.shade700),
                      title: const Text('Message Template'),
                      subtitle: Text(
                        _whatsappService.messageTemplate.length > 50
                            ? '${_whatsappService.messageTemplate.substring(0, 50)}...'
                            : _whatsappService.messageTemplate,
                      ),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () => _showWhatsAppMessageDialog(context),
                    ),
                  ),
                ],

                const Divider(height: 32),
              ],

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
        thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.primary;
          }
          return Colors.grey;
        }),
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

  Future<void> _showGoogleSheetsUrlDialog(BuildContext context) async {
    final controller = TextEditingController(text: _googleSheetsService.webhookUrl);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sheets Webhook URL'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your Google Apps Script webhook URL:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.url,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Webhook URL',
                  hintText: 'https://script.google.com/macros/s/.../exec',
                  helperText: 'Get this from your Google Apps Script deployment',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Webhook URL is required';
                  }
                  if (!value.startsWith('https://')) {
                    return 'URL must start with https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Tip: See GOOGLE_SHEETS_SETUP.md for step-by-step instructions',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _googleSheetsService.updateSettings(
                  webhookUrl: controller.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Webhook URL updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _testGoogleSheetsWebhook(BuildContext context) async {
    if (_googleSheetsService.webhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure webhook URL first')),
      );
      return;
    }

    // Show loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final success = await _googleSheetsService.testWebhook();

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Webhook test successful! Google Sheets is ready.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Webhook test failed. Please check your URL and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showWhatsAppPhoneDialog(BuildContext context) async {
    final controller = TextEditingController(text: _whatsappService.phoneNumber);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure WhatsApp Number'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+911234567890',
                  helperText: 'Include country code (e.g., +91 for India)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
                  if (cleaned.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _whatsappService.updateSettings(
                  phoneNumber: controller.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('WhatsApp number updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWhatsAppMessageDialog(BuildContext context) async {
    final controller = TextEditingController(text: _whatsappService.messageTemplate);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Available placeholders:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '{date} - Detection date\n'
              '{time} - Detection time\n'
              '{description} - Event description\n'
              '{confidence} - Confidence percentage',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Message Template',
                border: OutlineInputBorder(),
              ),
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
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message template cannot be empty')),
                );
                return;
              }
              await _whatsappService.updateSettings(
                messageTemplate: controller.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message template updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
