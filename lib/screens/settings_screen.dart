import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movement_provider.dart';
import 'known_persons_screen.dart';

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
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MovementProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Preferences',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          Text(
                            'Customize how you receive alerts',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // System Notifications
              _buildSettingTile(
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

              // Sound Alerts
              _buildSettingTile(
                context,
                icon: Icons.volume_up,
                title: 'Sound Alerts',
                subtitle: 'Play sound when movement detected',
                value: provider.enableSound,
                onChanged: (value) {
                  provider.updateNotificationSettings(
                    enableSound: value,
                  );
                },
              ),

              // Vibration
              _buildSettingTile(
                context,
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Vibrate device on detection',
                value: provider.enableVibration,
                onChanged: (value) {
                  provider.updateNotificationSettings(
                    enableVibration: value,
                  );
                },
              ),

              // Persistent Notification
              _buildSettingTile(
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

              // Identification Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.face, size: 24, color: Colors.purple),
                    const SizedBox(width: 12),
                    Text(
                      'Person Identification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),

              // Known Persons
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

              // Information Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Notifications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.info_outline,
                      title: 'System Notifications',
                      description:
                          'Appear in your notification tray even when the app is closed',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      icon: Icons.info_outline,
                      title: 'Sound Alerts',
                      description:
                          'Play an audible beep when movement is detected',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      icon: Icons.info_outline,
                      title: 'Vibration',
                      description:
                          'Vibrate for 500ms when movement is detected',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      icon: Icons.info_outline,
                      title: 'Persistent Notification',
                      description:
                          'Keeps monitoring service active and prevents Android from killing the app',
                    ),
                  ],
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to defaults'),
                      ),
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

  Widget _buildSettingTile(
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
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
