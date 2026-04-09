import 'package:flutter/foundation.dart';
import '../models/movement_event.dart';
import '../services/motion_detection_service.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class MovementProvider with ChangeNotifier {
  final MotionDetectionService _motionService;
  final NotificationService _notificationService = NotificationService.instance;
  
  List<MovementEvent> _movementEvents = [];
  bool _isMonitoring = false;
  bool _isRecording = false;
  String? _currentError;
  MovementEvent? _lastDetectedMovement;
  
  // Notification settings
  bool _enableSystemNotification = true;
  bool _enableSound = true;
  bool _enableVibration = true;
  bool _enablePersistentNotification = true;

  List<MovementEvent> get movementEvents => _movementEvents;
  bool get isMonitoring => _isMonitoring;
  bool get isRecording => _isRecording;
  String? get currentError => _currentError;
  MovementEvent? get lastDetectedMovement => _lastDetectedMovement;
  MotionDetectionService get motionService => _motionService;
  
  // Notification getters
  bool get enableSystemNotification => _enableSystemNotification;
  bool get enableSound => _enableSound;
  bool get enableVibration => _enableVibration;
  bool get enablePersistentNotification => _enablePersistentNotification;

  MovementProvider(this._motionService) {
    _motionService.onMovementDetected = _onMovementDetected;
    _motionService.onError = _onError;
  }

  Future<void> initialize() async {
    await _motionService.initialize();
    await _notificationService.initialize();
    await loadMovementHistory();
    notifyListeners();
  }

  Future<void> loadMovementHistory({int limit = 50}) async {
    try {
      _movementEvents = await DatabaseHelper.instance.readAll(limit: limit);
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to load movement history: $e';
      notifyListeners();
    }
  }

  Future<void> startMonitoring() async {
    try {
      await _motionService.startMonitoring();
      _isMonitoring = true;
      _currentError = null;
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to start monitoring: $e';
      notifyListeners();
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _motionService.stopMonitoring();
      _isMonitoring = false;
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to stop monitoring: $e';
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    try {
      await _motionService.startRecording();
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to start recording: $e';
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    try {
      await _motionService.stopRecording();
      _isRecording = false;
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to stop recording: $e';
      notifyListeners();
    }
  }

  Future<void> deleteMovement(int id) async {
    try {
      await DatabaseHelper.instance.delete(id);
      _movementEvents.removeWhere((event) => event.id == id);
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to delete movement event: $e';
      notifyListeners();
    }
  }

  Future<void> clearAllMovements() async {
    try {
      await DatabaseHelper.instance.deleteAll();
      _movementEvents.clear();
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to clear movement history: $e';
      notifyListeners();
    }
  }

  void _onMovementDetected(MovementEvent event) {
    _lastDetectedMovement = event;
    _movementEvents.insert(0, event);
    notifyListeners();
  }

  void _onError(String error) {
    _currentError = error;
    notifyListeners();
  }

  void clearError() {
    _currentError = null;
    notifyListeners();
  }

  /// Update notification settings
  Future<void> updateNotificationSettings({
    bool? enableSystemNotification,
    bool? enableSound,
    bool? enableVibration,
    bool? enablePersistentNotification,
  }) async {
    _notificationService.updateSettings(
      enableSystemNotification: enableSystemNotification,
      enableSound: enableSound,
      enableVibration: enableVibration,
      enablePersistentNotification: enablePersistentNotification,
    );

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
    
    notifyListeners();
  }

  /// Get notification settings
  Map<String, bool> getNotificationSettings() {
    return _notificationService.getSettings();
  }

  @override
  void dispose() {
    _motionService.dispose();
    super.dispose();
  }
}
