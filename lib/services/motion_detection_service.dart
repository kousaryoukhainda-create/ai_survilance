import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../models/movement_event.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'identification_service.dart';
import 'whatsapp_service.dart';
import 'google_sheets_service.dart';

/// Represents a detected object's bounding box for live overlay
class DetectionBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;
  final double confidence;

  const DetectionBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });
}

class MotionDetectionService {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // Motion detection parameters
  img.Image? _previousFrame;
  bool _isDetecting = false;
  Timer? _detectionTimer;

  // Configurable thresholds (defaults match original hardcoded values)
  double _motionThreshold = 30.0;
  double _pixelDifferenceThreshold = 25.0;

  // Services
  final NotificationService _notificationService = NotificationService.instance;
  final IdentificationService _identificationService = IdentificationService.instance;
  final WhatsAppService _whatsappService = WhatsAppService.instance;
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService.instance;

  // Identification settings
  final bool _enableIdentification = true;

  // Live detection boxes
  bool _enableLiveDetectionBoxes = true;
  final List<DetectionBox> _currentDetectionBoxes = [];
  Timer? _liveDetectionTimer;

  // Camera capture lock to prevent concurrent takePicture calls
  bool _isTakingPicture = false;
  DateTime? _lastCaptureTime;
  static const Duration _minCaptureInterval = Duration(milliseconds: 600);

  // Callbacks
  Function(MovementEvent event)? onMovementDetected;
  Function(String error)? onError;
  Function(List<DetectionBox> boxes)? onDetectionBoxesUpdated;

  // State
  bool _isMonitoring = false;
  bool _isRecording = false;

  bool get isMonitoring => _isMonitoring;
  bool get isRecording => _isRecording;
  bool get isInitialized => _cameraController != null && _cameraController!.value.isInitialized;
  bool get enableIdentification => _enableIdentification;
  bool get enableLiveDetectionBoxes => _enableLiveDetectionBoxes;
  double get motionThreshold => _motionThreshold;
  double get pixelDifferenceThreshold => _pixelDifferenceThreshold;
  List<DetectionBox> get currentDetectionBoxes => List.unmodifiable(_currentDetectionBoxes);

  MotionDetectionService({this.onMovementDetected, this.onError, this.onDetectionBoxesUpdated});

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        onError?.call('No cameras available');
        return;
      }

      // Use back camera by default
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      // Initialize identification service
      await _identificationService.initialize();
    } catch (e) {
      onError?.call('Failed to initialize camera: $e');
    }
  }

  CameraController? get cameraController => _cameraController;

  Future<void> startMonitoring() async {
    if (!isInitialized) {
      onError?.call('Camera not initialized');
      return;
    }

    _isMonitoring = true;

    // Show persistent notification
    await _notificationService.showPersistentNotification();

    // Start live detection for bounding boxes
    if (_enableLiveDetectionBoxes) {
      _startLiveDetection();
    }

    // Start periodic frame capture
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 500), // Check every 500ms
      (_) => _captureAndAnalyzeFrame(),
    );
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;

    // Stop live detection
    _liveDetectionTimer?.cancel();
    _liveDetectionTimer = null;
    _currentDetectionBoxes.clear();
    onDetectionBoxesUpdated?.call([]);

    // Hide persistent notification
    await _notificationService.hidePersistentNotification();
  }

  /// Start live object detection for bounding box overlays
  void _startLiveDetection() {
    _liveDetectionTimer?.cancel();
    _liveDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 1000), // Update every second
      (_) => _updateDetectionBoxes(),
    );
  }

  bool _isCapturingBoxes = false;

  /// Update detection boxes from ML Kit object detection
  Future<void> _updateDetectionBoxes() async {
    if (!_enableLiveDetectionBoxes || _cameraController == null || !_isMonitoring) return;
    if (_isTakingPicture) return;

    // Check minimum interval since last capture
    if (_lastCaptureTime != null) {
      final timeSinceLastCapture = DateTime.now().difference(_lastCaptureTime!);
      if (timeSinceLastCapture < _minCaptureInterval) return;
    }

    _isTakingPicture = true;
    _lastCaptureTime = DateTime.now();

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      if (_identificationService.isInitialized) {
        final result = await _identificationService.analyzeFrame(inputImage);

        _currentDetectionBoxes.clear();

        for (final obj in result.objects) {
          if (obj.labels.isNotEmpty) {
            final label = obj.labels.first;
            final box = obj.boundingBox;

            _currentDetectionBoxes.add(DetectionBox(
              x: box.left.toDouble(),
              y: box.top.toDouble(),
              width: box.width.toDouble(),
              height: box.height.toDouble(),
              label: label.text,
              confidence: label.confidence,
            ));
          }
        }

        onDetectionBoxesUpdated?.call(List.unmodifiable(_currentDetectionBoxes));
      }

      // Clean up temp image
      final tempFile = File(image.path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      // Silently fail for live detection (non-critical)
    } finally {
      _isTakingPicture = false;
    }
  }

  Future<void> _captureAndAnalyzeFrame() async {
    if (_isDetecting || !_isMonitoring || _isTakingPicture) return;

    // Check minimum interval since last capture
    if (_lastCaptureTime != null) {
      final timeSinceLastCapture = DateTime.now().difference(_lastCaptureTime!);
      if (timeSinceLastCapture < _minCaptureInterval) return;
    }

    _isDetecting = true;
    _isTakingPicture = true;
    _lastCaptureTime = DateTime.now();

    try {
      final XFile image = await _cameraController!.takePicture();
      final currentFrame = await _loadImage(image.path);

      if (currentFrame != null) {
        final processedFrame = img.copyResize(
          currentFrame,
          width: 160,
          height: 120,
        );

        if (_previousFrame != null) {
          final motionScore = _calculateMotionDifference(_previousFrame!, processedFrame);

          if (motionScore > motionThreshold) {
            final confidence = (motionScore / 100.0).clamp(0.0, 1.0);
            await _handleMovementDetected(image.path, confidence);
          } else {
            await _deleteTempImage(image.path);
          }
        } else {
          _previousFrame = processedFrame;
          await _deleteTempImage(image.path);
        }
      } else {
        await _deleteTempImage(image.path);
      }
    } catch (e) {
      onError?.call('Error during frame analysis: $e');
    } finally {
      _isDetecting = false;
      _isTakingPicture = false;
    }
  }

  Future<void> _deleteTempImage(String path) async {
    try {
      final tempFile = File(path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}
  }

  double motionScore(img.Image frame1, img.Image frame2) {
    return _calculateMotionDifference(frame1, frame2);
  }

  double _calculateMotionDifference(img.Image frame1, img.Image frame2) {
    int differentPixels = 0;
    final totalPixels = frame1.width * frame1.height;

    for (int y = 0; y < frame1.height; y++) {
      for (int x = 0; x < frame1.width; x++) {
        final pixel1 = frame1.getPixel(x, y);
        final pixel2 = frame2.getPixel(x, y);

        // Calculate grayscale difference
        final gray1 = (pixel1.r + pixel1.g + pixel1.b) / 3.0;
        final gray2 = (pixel2.r + pixel2.g + pixel2.b) / 3.0;

        if ((gray1 - gray2).abs() > pixelDifferenceThreshold) {
          differentPixels++;
        }
      }
    }

    return (differentPixels / totalPixels) * 100;
  }

  Future<img.Image?> _loadImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      
      final bytes = await file.readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      onError?.call('Error loading image: $e');
      return null;
    }
  }

  Future<void> _handleMovementDetected(String imagePath, double confidence) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final snapshotsDir = Directory('${appDir.path}/snapshots');
      if (!await snapshotsDir.exists()) {
        await snapshotsDir.create(recursive: true);
      }

      // Save snapshot with timestamp
      final timestamp = DateTime.now();
      final fileName = 'movement_${timestamp.millisecondsSinceEpoch}.jpg';
      final snapshotPath = '${snapshotsDir.path}/$fileName';

      final sourceFile = File(imagePath);
      await sourceFile.copy(snapshotPath);

      // Initialize identification result
      String? detectedType;
      String? identityName;
      double? identityConfidence;
      bool isFaceMatched = false;
      String? objectsDetected;
      int? personCount;

      // Run identification if enabled
      if (_enableIdentification && _identificationService.isInitialized) {
        try {
          final inputImage = InputImage.fromFilePath(snapshotPath);
          final result = await _identificationService.analyzeFrame(inputImage);
          
          detectedType = result.detectedType;
          identityName = result.identityName;
          identityConfidence = result.identityConfidence;
          isFaceMatched = result.isFaceMatched;
          personCount = result.personCount;
          
          if (result.objects.isNotEmpty) {
            objectsDetected = jsonEncode(result.getObjectLabels());
          }
        } catch (e) {
          debugPrint('Error during identification: $e');
        }
      }

      // Build description based on identification
      String description;
      if (identityName != null) {
        description = '$identityName detected (${(identityConfidence! * 100).toStringAsFixed(1)}%)';
      } else if (detectedType == 'person') {
        description = personCount != null 
            ? '$personCount person${personCount > 1 ? 's' : ''} detected'
            : 'Person detected';
      } else if (detectedType != null) {
        description = '${detectedType[0].toUpperCase()}${detectedType.substring(1)} detected';
      } else {
        description = 'Movement detected (${(confidence * 100).toStringAsFixed(1)}% confidence)';
      }

      // Create movement event
      final event = MovementEvent(
        timestamp: timestamp,
        snapshotPath: snapshotPath,
        confidence: confidence,
        description: description,
        detectedType: detectedType,
        identityName: identityName,
        identityConfidence: identityConfidence,
        isFaceMatched: isFaceMatched,
        objectsDetected: objectsDetected,
        personCount: personCount,
      );

      // Save to database
      await DatabaseHelper.instance.create(event);

      // Show system notification
      await _notificationService.showMovementNotification(event);

      // Auto-share to WhatsApp if enabled
      if (_whatsappService.isConfigured) {
        try {
          if (event.videoPath != null && event.videoPath!.isNotEmpty && _whatsappService.shareVideos) {
            await _whatsappService.shareVideo(
              videoPath: event.videoPath!,
              description: event.description,
              timestamp: event.timestamp,
              confidence: event.confidence,
            );
          } else if (_whatsappService.shareSnapshots) {
            await _whatsappService.shareSnapshot(
              snapshotPath: event.snapshotPath,
              description: event.description,
              timestamp: event.timestamp,
              confidence: event.confidence,
            );
          }
        } catch (e) {
          debugPrint('Error auto-sharing to WhatsApp: $e');
        }
      }

      // Auto-upload to Google Sheets if enabled (fully automatic)
      if (_googleSheetsService.isConfigured) {
        try {
          await _googleSheetsService.uploadDetection(
            description: event.description,
            timestamp: event.timestamp,
            confidence: event.confidence,
            snapshotPath: event.snapshotPath,
            videoPath: event.videoPath,
            detectedType: event.detectedType,
            identityName: event.identityName,
            identityConfidence: event.identityConfidence,
            personCount: event.personCount,
          );
        } catch (e) {
          debugPrint('Error uploading to Google Sheets: $e');
        }
      }

      // Notify listeners
      onMovementDetected?.call(event);
    } catch (e) {
      onError?.call('Error saving movement event: $e');
    }
  }

  Future<void> startRecording() async {
    if (!isInitialized || _isRecording || _cameraController == null) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      _isRecording = true;
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      await _cameraController!.startVideoRecording();
    } catch (e) {
      onError?.call('Error starting recording: $e');
      _isRecording = false;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording || _cameraController == null) return null;

    try {
      final videoPath = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      
      // Copy video to app directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'manual_recording_$timestamp.mp4';
      final destPath = '${videosDir.path}/$fileName';
      
      final sourceFile = File(videoPath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destPath);
        return destPath;
      }
      
      return videoPath;
    } catch (e) {
      onError?.call('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> dispose() async {
    await stopMonitoring();
    await _cameraController?.dispose();
    _previousFrame = null;
    await _notificationService.dispose();
  }

  /// Update motion detection thresholds
  void updateThresholds({
    double? motionThreshold,
    double? pixelDifferenceThreshold,
  }) {
    if (motionThreshold != null && motionThreshold >= 0 && motionThreshold <= 100) {
      _motionThreshold = motionThreshold;
    }
    if (pixelDifferenceThreshold != null && pixelDifferenceThreshold >= 0 && pixelDifferenceThreshold <= 255) {
      _pixelDifferenceThreshold = pixelDifferenceThreshold;
    }
  }

  /// Enable or disable live detection boxes
  void setLiveDetectionBoxes(bool value) {
    _enableLiveDetectionBoxes = value;
    if (!value) {
      _currentDetectionBoxes.clear();
      onDetectionBoxesUpdated?.call([]);
    } else if (_isMonitoring) {
      _startLiveDetection();
    }
  }

  /// Get current detection settings
  Map<String, dynamic> getDetectionSettings() {
    return {
      'motionThreshold': _motionThreshold,
      'pixelDifferenceThreshold': _pixelDifferenceThreshold,
      'enableLiveDetectionBoxes': _enableLiveDetectionBoxes,
    };
  }
}
