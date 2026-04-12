import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._init();

  PermissionService._init();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    // On Android 13+ (API 33+), use photos and videos permissions
    // On older versions and iOS, use the legacy storage permission
    final photosStatus = await Permission.photos.request();
    final videosStatus = await Permission.videos.request();
    
    // If photos/videos permissions are granted (Android 13+), return true
    // If they're permanently denied, fallback to storage permission
    if (photosStatus.isGranted && videosStatus.isGranted) {
      return true;
    }
    
    // Fallback for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
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
    // Request core permissions
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ];

    return await permissions.request();
  }

  Future<bool> areAllPermissionsGranted() async {
    final cameraGranted = await Permission.camera.isGranted;
    final microphoneGranted = await Permission.microphone.isGranted;
    final notificationGranted = await Permission.notification.isGranted;
    
    // Check both new (photos/videos) and legacy (storage) permissions
    final photosGranted = await Permission.photos.isGranted;
    final videosGranted = await Permission.videos.isGranted;
    final storageGranted = await Permission.storage.isGranted;
    
    // Storage is granted if either new or legacy permissions are granted
    final hasStoragePermission = (photosGranted && videosGranted) || storageGranted;

    return cameraGranted && hasStoragePermission && microphoneGranted && notificationGranted;
  }
}
