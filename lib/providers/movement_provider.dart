import 'package:flutter/foundation.dart';
import '../models/movement_event.dart';
import '../services/motion_detection_service.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../services/storage_service.dart';

class MovementProvider with ChangeNotifier {
  final MotionDetectionService _motionService;
  final NotificationService _notificationService = NotificationService.instance;
  final ScheduleService _scheduleService = ScheduleService.instance;
  final StorageService _storageService = StorageService.instance;

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

  // Detection settings
  double _motionThreshold = 30.0;
  double _pixelDifferenceThreshold = 25.0;
  bool _enableLiveDetectionBoxes = true;

  // Storage info
  StorageInfo? _storageInfo;

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

  // Detection getters
  double get motionThreshold => _motionThreshold;
  double get pixelDifferenceThreshold => _pixelDifferenceThreshold;
  bool get enableLiveDetectionBoxes => _enableLiveDetectionBoxes;

  // Schedule getters
  ScheduleService get scheduleService => _scheduleService;
  StorageService get storageService => _storageService;
  StorageInfo? get storageInfo => _storageInfo;

  MovementProvider(this._motionService) {
    _motionService.onMovementDetected = _onMovementDetected;
    _motionService.onError = _onError;
  }

  Future<void> initialize() async {
    await _motionService.initialize();
    await _notificationService.initialize();
    await _scheduleService.initialize();
    await loadMovementHistory();
    await loadStorageInfo();
    _loadDetectionSettings();
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

  /// Load detection settings from service
  void _loadDetectionSettings() {
    final settings = _motionService.getDetectionSettings();
    _motionThreshold = settings['motionThreshold'] as double? ?? 30.0;
    _pixelDifferenceThreshold = settings['pixelDifferenceThreshold'] as double? ?? 25.0;
    _enableLiveDetectionBoxes = settings['enableLiveDetectionBoxes'] as bool? ?? true;
  }

  /// Update motion detection thresholds
  Future<void> updateDetectionThresholds({
    double? motionThreshold,
    double? pixelDifferenceThreshold,
  }) async {
    _motionService.updateThresholds(
      motionThreshold: motionThreshold,
      pixelDifferenceThreshold: pixelDifferenceThreshold,
    );

    if (motionThreshold != null) _motionThreshold = motionThreshold;
    if (pixelDifferenceThreshold != null) _pixelDifferenceThreshold = pixelDifferenceThreshold;

    notifyListeners();
  }

  /// Toggle live detection boxes
  Future<void> setLiveDetectionBoxes(bool value) async {
    _motionService.setLiveDetectionBoxes(value);
    _enableLiveDetectionBoxes = value;
    notifyListeners();
  }

  /// Load storage information
  Future<void> loadStorageInfo() async {
    try {
      _storageInfo = await _storageService.getStorageInfo();
      notifyListeners();
    } catch (e) {
      _currentError = 'Failed to load storage info: $e';
      notifyListeners();
    }
  }

  /// Auto-delete old events
  Future<int> autoDeleteOldEvents(int days) async {
    final deleted = await _storageService.autoDeleteOldEvents(days);
    await loadMovementHistory();
    await loadStorageInfo();
    return deleted;
  }

  /// Clear all snapshots
  Future<int> clearAllSnapshots() async {
    final deleted = await _storageService.clearAllSnapshots();
    await loadStorageInfo();
    return deleted;
  }

  /// Clear all videos
  Future<int> clearAllVideos() async {
    final deleted = await _storageService.clearAllVideos();
    await loadStorageInfo();
    return deleted;
  }

  @override
  void dispose() {
    _motionService.dispose();
    super.dispose();
  }
}
