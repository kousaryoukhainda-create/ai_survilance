import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/movement_provider.dart';
import 'movement_history_screen.dart';
import 'movement_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovementProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MovementHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MovementProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Error banner
              if (provider.currentError != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.currentError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => provider.clearError(),
                      ),
                    ],
                  ),
                ),

              // Camera preview
              Expanded(
                flex: 3,
                child: _buildCameraPreview(provider),
              ),

              // Status and controls
              Expanded(
                flex: 2,
                child: _buildControls(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(MovementProvider provider) {
    if (provider.motionService.cameraController == null ||
        !provider.motionService.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(provider.motionService.cameraController!),
        
        // Monitoring indicator
        if (provider.isMonitoring)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'MONITORING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Recording indicator
        if (provider.isRecording)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Last movement notification
        if (provider.lastDetectedMovement != null && provider.isMonitoring)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.motion_photos_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Movement Detected!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(provider.lastDetectedMovement!.confidence * 100).toStringAsFixed(1)}% confidence',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls(MovementProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider.isMonitoring ? Icons.visibility : Icons.visibility_off,
                color: provider.isMonitoring ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                provider.isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: provider.isMonitoring ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Control buttons
          Row(
            children: [
              // Monitor button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isMonitoring
                      ? () => provider.stopMonitoring()
                      : () => provider.startMonitoring(),
                  icon: Icon(
                    provider.isMonitoring ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(provider.isMonitoring ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isMonitoring
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Record button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.motionService.isInitialized
                      ? (provider.isRecording
                          ? () => provider.stopRecording()
                          : () => provider.startRecording())
                      : null,
                  icon: Icon(provider.isRecording ? Icons.stop : Icons.videocam),
                  label: Text(provider.isRecording ? 'Stop Rec' : 'Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isRecording
                        ? Colors.orange
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                Icons.motion_photos_on,
                '${provider.movementEvents.length}',
                'Detections',
              ),
              _buildStatCard(
                Icons.access_time,
                provider.lastDetectedMovement != null
                    ? _formatTime(provider.lastDetectedMovement!.timestamp)
                    : '--:--',
                'Last Event',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
