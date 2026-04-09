import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/movement_event.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Notification settings
  bool _enableSystemNotification = true;
  bool _enableSound = true;
  bool _enableVibration = true;
  bool _enablePersistentNotification = true;
  
  // Notification IDs
  static const int _movementNotificationId = 1;
  static const int _persistentNotificationId = 0;
  
  // Channel IDs
  static const String _movementChannelId = 'movement_detection_channel';
  static const String _persistentChannelId = 'persistent_monitoring_channel';
  
  bool get enableSystemNotification => _enableSystemNotification;
  bool get enableSound => _enableSound;
  bool get enableVibration => _enableVibration;
  bool get enablePersistentNotification => _enablePersistentNotification;

  NotificationService._init();

  /// Initialize notification service
  Future<void> initialize() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Movement detection channel
    const movementChannel = AndroidNotificationChannel(
      _movementChannelId,
      'Movement Detections',
      description: 'Notifications when movement is detected',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Persistent monitoring channel
    const persistentChannel = AndroidNotificationChannel(
      _persistentChannelId,
      'Monitoring Service',
      description: 'Shows when monitoring is active',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(movementChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(persistentChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // This will be handled by the app to navigate to details
    print('Notification tapped: ${response.payload}');
  }

  /// Show movement detection notification
  Future<void> showMovementNotification(MovementEvent event) async {
    if (!_enableSystemNotification) return;

    final androidDetails = AndroidNotificationDetails(
      _movementChannelId,
      'Movement Detections',
      channelDescription: 'Notifications when movement is detected',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: _enableSound,
      enableVibration: _enableVibration,
      styleInformation: BigTextStyleInformation(
        '${event.description}\nTime: ${_formatDateTime(event.timestamp)}\nConfidence: ${(event.confidence * 100).toStringAsFixed(1)}%',
        contentTitle: 'Movement Detected!',
        summaryText: 'Tap to view details',
      ),
      actions: [
        AndroidNotificationAction(
          'view_details',
          'View Details',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'stop_monitoring',
          'Stop Monitoring',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _movementNotificationId,
      'Movement Detected!',
      '${(event.confidence * 100).toStringAsFixed(1)}% confidence at ${_formatTime(event.timestamp)}',
      notificationDetails,
      payload: 'movement_${event.id}',
    );

    // Play sound if enabled
    if (_enableSound) {
      await _playDetectionSound();
    }

    // Vibrate if enabled
    if (_enableVibration) {
      await _vibrate();
    }
  }

  /// Show persistent monitoring notification
  Future<void> showPersistentNotification() async {
    if (!_enablePersistentNotification) return;

    const androidDetails = AndroidNotificationDetails(
      _persistentChannelId,
      'Monitoring Service',
      channelDescription: 'Shows when monitoring is active',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      playSound: false,
      enableVibration: false,
      ongoing: true, // Makes it persistent
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
          'stop_monitoring',
          'Stop',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _persistentNotificationId,
      'Monitoring Active',
      'Movement detection is running',
      notificationDetails,
      payload: 'persistent_monitoring',
    );
  }

  /// Hide persistent notification
  Future<void> hidePersistentNotification() async {
    await _notifications.cancel(_persistentNotificationId);
  }

  /// Cancel movement notification
  Future<void> cancelMovementNotification() async {
    await _notifications.cancel(_movementNotificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Play detection sound
  Future<void> _playDetectionSound() async {
    try {
      // Using a default notification sound
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      // Note: In production, you would include a sound file in assets
      // await _audioPlayer.play(AssetSource('sounds/detection_beep.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  /// Vibrate device
  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      print('Error vibrating: $e');
    }
  }

  /// Update notification settings
  void updateSettings({
    bool? enableSystemNotification,
    bool? enableSound,
    bool? enableVibration,
    bool? enablePersistentNotification,
  }) {
    if (enableSystemNotification != null) {
      _enableSystemNotification = enableSystemNotification;
    }
    if (enableSound != null) {
      _enableSound = enableSound;
    }
    if (enableVibration != null) {
      _enableVibration = enableVibration;
    }
    if (enablePersistentNotification != null) {
      _enablePersistentNotification = enablePersistentNotification;
    }
  }

  /// Get current settings as map
  Map<String, bool> getSettings() {
    return {
      'enableSystemNotification': _enableSystemNotification,
      'enableSound': _enableSound,
      'enableVibration': _enableVibration,
      'enablePersistentNotification': _enablePersistentNotification,
    };
  }

  /// Format time for notification display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format full date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await cancelAllNotifications();
  }
}
