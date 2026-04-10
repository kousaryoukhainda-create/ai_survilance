import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movement_provider.dart';
import '../services/storage_service.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool _isLoading = true;
  int _autoDeleteDays = 30;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);
    await context.read<MovementProvider>().loadStorageInfo();
    setState(() => _isLoading = false);
  }

  Future<void> _confirmAutoDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Delete Old Events'),
        content: Text(
          'Delete all movement events and snapshots older than $_autoDeleteDays days. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await context.read<MovementProvider>().autoDeleteOldEvents(_autoDeleteDays);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $deleted old events'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearSnapshots() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Snapshots'),
        content: const Text('Delete all saved snapshot images. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await context.read<MovementProvider>().clearAllSnapshots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $deleted snapshots'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearVideos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Videos'),
        content: const Text('Delete all saved video recordings. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await context.read<MovementProvider>().clearAllVideos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $deleted videos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MovementProvider>(
        builder: (context, provider, child) {
          if (_isLoading || provider.storageInfo == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final info = provider.storageInfo!;

          return RefreshIndicator(
            onRefresh: _loadStorageInfo,
            child: ListView(
              children: [
                // Total usage header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.storage, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        info.totalFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total Storage Used',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Breakdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Storage Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                _buildStorageItem(
                  context,
                  icon: Icons.image,
                  title: 'Snapshots',
                  size: info.snapshotsFormatted,
                  count: '${info.snapshotCount} files',
                  color: Colors.blue,
                ),

                _buildStorageItem(
                  context,
                  icon: Icons.videocam,
                  title: 'Videos',
                  size: info.videosFormatted,
                  count: '${info.videoCount} files',
                  color: Colors.orange,
                ),

                _buildStorageItem(
                  context,
                  icon: Icons.people,
                  title: 'Known Persons',
                  size: info.personsFormatted,
                  count: '${info.personCount} persons',
                  color: Colors.purple,
                ),

                _buildStorageItem(
                  context,
                  icon: Icons.storage,
                  title: 'Database',
                  size: info.databaseFormatted,
                  count: '${info.eventCount} events',
                  color: Colors.green,
                ),

                const Divider(height: 32),

                // Cleanup actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Cleanup Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                // Auto-delete old events
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.auto_delete, color: Colors.red.shade700),
                    title: const Text('Auto-Delete Old Events'),
                    subtitle: Text('Delete events older than $_autoDeleteDays days'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showAutoDeleteDialog(),
                  ),
                ),

                // Clear snapshots
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep, color: Colors.orange),
                    title: const Text('Clear All Snapshots'),
                    subtitle: const Text('Remove all saved images'),
                    onTap: _confirmClearSnapshots,
                  ),
                ),

                // Clear videos
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.video_library, color: Colors.blue),
                    title: const Text('Clear All Videos'),
                    subtitle: const Text('Remove all video recordings'),
                    onTap: _confirmClearVideos,
                  ),
                ),

                const SizedBox(height: 16),

                // Refresh button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: _loadStorageInfo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Storage Info'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStorageItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String size,
    required String count,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(count),
        trailing: Text(
          size,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Future<void> _showAutoDeleteDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Auto-Delete Old Events'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Delete events older than:'),
              const SizedBox(height: 16),
              Slider(
                value: _autoDeleteDays.toDouble(),
                min: 1,
                max: 365,
                divisions: 364,
                label: '$_autoDeleteDays days',
                onChanged: (value) {
                  setDialogState(() {
                    _autoDeleteDays = value.round();
                  });
                },
              ),
              Text(
                '$_autoDeleteDays days',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmAutoDelete();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
