import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._init();
  
  PermissionService._init();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    // For Android 13+, notification permission is required
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestAllPermissions() async {
    final cameraGranted = await requestCameraPermission();
    final storageGranted = await requestStoragePermission();
    final microphoneGranted = await requestMicrophonePermission();
    final notificationGranted = await requestNotificationPermission();
    
    return cameraGranted && storageGranted && microphoneGranted && notificationGranted;
  }

  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return await [
      Permission.camera,
      Permission.storage,
      Permission.microphone,
      Permission.notification,
    ].request();
  }

  Future<bool> areAllPermissionsGranted() async {
    final cameraGranted = await Permission.camera.isGranted;
    final storageGranted = await Permission.storage.isGranted;
    final microphoneGranted = await Permission.microphone.isGranted;
    final notificationGranted = await Permission.notification.isGranted;
    
    return cameraGranted && storageGranted && microphoneGranted && notificationGranted;
  }
}
