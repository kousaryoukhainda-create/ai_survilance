import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/movement_event.dart';

class MovementDetailScreen extends StatelessWidget {
  final MovementEvent event;

  const MovementDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement Event Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Snapshot image
            _buildSnapshotImage(),

            // Event details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Confidence level
                  _buildConfidenceCard(context),
                  const SizedBox(height: 16),

                  // Timestamp
                  _buildDetailCard(
                    context,
                    Icons.access_time,
                    'Timestamp',
                    DateFormat('MMMM dd, yyyy').format(event.timestamp),
                    DateFormat('HH:mm:ss').format(event.timestamp),
                  ),
                  const SizedBox(height: 16),

                  // File path
                  _buildDetailCard(
                    context,
                    Icons.folder,
                    'Snapshot Location',
                    'File Path',
                    event.snapshotPath,
                  ),

                  // Video path if exists
                  if (event.videoPath != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      context,
                      Icons.videocam,
                      'Video Recording',
                      'Video Path',
                      event.videoPath!,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareSnapshot(context),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _viewFullScreen(context),
                          icon: const Icon(Icons.fullscreen),
                          label: const Text('View Full'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotImage() {
    final file = File(event.snapshotPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
      );
    }

    return Container(
      height: 300,
      color: Colors.grey.shade300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('Snapshot not found'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: _getConfidenceColor(event.confidence),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Confidence Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: event.confidence,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getConfidenceColor(event.confidence),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(event.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getConfidenceColor(event.confidence),
              ),
            ),
            Text(
              _getConfidenceLabel(event.confidence),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence > 0.8) return 'Very High';
    if (confidence > 0.6) return 'High';
    if (confidence > 0.4) return 'Medium';
    if (confidence > 0.2) return 'Low';
    return 'Very Low';
  }

  void _shareSnapshot(BuildContext context) {
    final file = File(event.snapshotPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot file not found')),
      );
      return;
    }

    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon')),
    );
  }

  void _viewFullScreen(BuildContext context) {
    final file = File(event.snapshotPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot file not found')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                file,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
