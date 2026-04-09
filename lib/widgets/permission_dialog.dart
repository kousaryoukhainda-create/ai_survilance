import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionDialog extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionDialog({super.key, required this.onPermissionsGranted});

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  final PermissionService _permissionService = PermissionService.instance;
  bool _isRequesting = false;
  String? _error;

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
      _error = null;
    });

    try {
      final granted = await _permissionService.requestAllPermissions();
      
      if (granted) {
        widget.onPermissionsGranted();
      } else {
        setState(() {
          _error = 'Some permissions were not granted. Please enable them in settings.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to request permissions: $e';
      });
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Permissions Needed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This app requires the following permissions to function properly:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildPermissionItem(Icons.camera_alt, 'Camera', 'To detect movement'),
            const SizedBox(height: 12),
            _buildPermissionItem(Icons.storage, 'Storage', 'To save snapshots and recordings'),
            const SizedBox(height: 12),
            _buildPermissionItem(Icons.mic, 'Microphone', 'To record audio with videos'),
            const SizedBox(height: 12),
            _buildPermissionItem(Icons.notifications, 'Notifications', 'To alert on movement detection'),
            const SizedBox(height: 12),
            _buildPermissionItem(Icons.vibration, 'Vibration', 'To vibrate on movement detection'),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRequesting ? null : _requestPermissions,
                icon: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isRequesting ? 'Requesting...' : 'Grant Permissions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
