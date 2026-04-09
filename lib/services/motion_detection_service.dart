import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../models/movement_event.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'identification_service.dart';

class MotionDetectionService {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  // Motion detection parameters
  img.Image? _previousFrame;
  bool _isDetecting = false;
  Timer? _detectionTimer;
  
  // Thresholds
  final double motionThreshold = 30.0;
  final double pixelDifferenceThreshold = 25.0;
  
  // Services
  final NotificationService _notificationService = NotificationService.instance;
  final IdentificationService _identificationService = IdentificationService.instance;
  
  // Identification settings
  bool _enableIdentification = true;
  
  // Callbacks
  final Function(MovementEvent event)? onMovementDetected;
  final Function(String error)? onError;
  
  // State
  bool _isMonitoring = false;
  bool _isRecording = false;
  
  bool get isMonitoring => _isMonitoring;
  bool get isRecording => _isRecording;
  bool get isInitialized => _cameraController != null && _cameraController!.value.isInitialized;
  bool get enableIdentification => _enableIdentification;

  MotionDetectionService({this.onMovementDetected, this.onError});

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
    
    // Hide persistent notification
    await _notificationService.hidePersistentNotification();
  }

  Future<void> _captureAndAnalyzeFrame() async {
    if (_isDetecting || !_isMonitoring) return;

    _isDetecting = true;

    try {
      final image = await _cameraController!.takePicture();
      final currentFrame = await _loadImage(image.path);
      
      if (currentFrame != null) {
        // Resize for faster processing
        final processedFrame = img.copyResize(
          currentFrame,
          width: 160,
          height: 120,
        );

        if (_previousFrame != null) {
          final motionScore = _calculateMotionDifference(_previousFrame!, processedFrame);
          
          if (motionScore > motionThreshold) {
            // Movement detected!
            final confidence = (motionScore / 100.0).clamp(0.0, 1.0);
            await _handleMovementDetected(image.path, confidence);
          }
        }

        _previousFrame = processedFrame;
      }

      // Clean up the temporary image if not saving
      if (_previousFrame == null || motionScore(_previousFrame!, img.copyResize(currentFrame!, width: 160, height: 120)) <= motionThreshold) {
        final tempFile = File(image.path);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      onError?.call('Error during frame analysis: $e');
    } finally {
      _isDetecting = false;
    }
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
          print('Error during identification: $e');
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

      // Notify listeners
      onMovementDetected?.call(event);
    } catch (e) {
      onError?.call('Error saving movement event: $e');
    }
  }

  Future<void> startRecording() async {
    if (!isInitialized || _isRecording) return;

    try {
      _isRecording = true;
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoPath = '${videosDir.path}/recording_$timestamp.mp4';

      await _cameraController!.startVideoRecording(videoPath);
    } catch (e) {
      onError?.call('Error starting recording: $e');
      _isRecording = false;
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    try {
      await _cameraController!.stopVideoRecording();
      _isRecording = false;
    } catch (e) {
      onError?.call('Error stopping recording: $e');
    }
  }

  Future<void> dispose() async {
    await stopMonitoring();
    await _cameraController?.dispose();
    _previousFrame = null;
    await _notificationService.dispose();
  }
}
