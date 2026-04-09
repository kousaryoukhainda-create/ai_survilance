import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/movement_provider.dart';
import 'movement_detail_screen.dart';

class MovementHistoryScreen extends StatelessWidget {
  const MovementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<MovementProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: provider.movementEvents.isEmpty
                    ? null
                    : () => _confirmClearAll(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<MovementProvider>(
        builder: (context, provider, child) {
          if (provider.movementEvents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.motion_photos_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No movement events recorded',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMovementHistory(),
            child: ListView.builder(
              itemCount: provider.movementEvents.length,
              itemBuilder: (context, index) {
                final event = provider.movementEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: File(File(event.snapshotPath).existsSync())
                          ? Image.file(
                              File(event.snapshotPath),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    title: Text(
                      event.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm:ss').format(event.timestamp),
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: event.confidence,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getConfidenceColor(event.confidence),
                          ),
                        ),
                        Text(
                          '${(event.confidence * 100).toStringAsFixed(1)}% confidence',
                          style: TextStyle(
                            fontSize: 11,
                            color: _getConfidenceColor(event.confidence),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, provider, event.id!),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovementDetailScreen(event: event),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MovementProvider provider,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this movement event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteMovement(id);
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    MovementProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Events'),
        content: const Text(
          'Are you sure you want to delete all movement events? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearAllMovements();
    }
  }
}
