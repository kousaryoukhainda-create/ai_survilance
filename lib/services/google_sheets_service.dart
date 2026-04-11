import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GoogleSheetsService {
  static final GoogleSheetsService instance = GoogleSheetsService._init();

  // Settings keys
  static const String _keyEnabled = 'google_sheets_enabled';
  static const String _keyWebhookUrl = 'google_sheets_webhook_url';
  static const String _keyUploadImages = 'google_sheets_upload_images';
  static const String _keyUploadVideos = 'google_sheets_upload_videos';
  static const String _keyMaxRetries = 'google_sheets_max_retries';

  // Settings
  bool _isEnabled = false;
  String _webhookUrl = '';
  bool _uploadImages = true;
  bool _uploadVideos = false;
  int _maxRetries = 3;

  // State
  bool _isInitialized = false;
  int _consecutiveFailures = 0;
  bool _isCircuitBreakerOpen = false;
  DateTime? _lastFailureTime;

  // Error tracking
  final List<Map<String, dynamic>> _failedUploads = [];
  Function(String error)? onError;

  bool get isEnabled => _isEnabled;
  String get webhookUrl => _webhookUrl;
  bool get uploadImages => _uploadImages;
  bool get uploadVideos => _uploadVideos;
  int get maxRetries => _maxRetries;
  bool get isConfigured => _isEnabled && _webhookUrl.isNotEmpty;
  List<Map<String, dynamic>> get failedUploads => List.unmodifiable(_failedUploads);
  int get consecutiveFailures => _consecutiveFailures;
  bool get isCircuitBreakerOpen => _isCircuitBreakerOpen;

  GoogleSheetsService._init();

  /// Initialize Google Sheets service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_keyEnabled) ?? false;
      _webhookUrl = prefs.getString(_keyWebhookUrl) ?? '';
      _uploadImages = prefs.getBool(_keyUploadImages) ?? true;
      _uploadVideos = prefs.getBool(_keyUploadVideos) ?? false;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Google Sheets service: $e');
    }
  }

  /// Update settings
  Future<void> updateSettings({
    bool? enabled,
    String? webhookUrl,
    bool? uploadImages,
    bool? uploadVideos,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (enabled != null) {
        _isEnabled = enabled;
        await prefs.setBool(_keyEnabled, enabled);
      }

      if (webhookUrl != null) {
        _webhookUrl = webhookUrl.trim();
        await prefs.setString(_keyWebhookUrl, _webhookUrl);
      }

      if (uploadImages != null) {
        _uploadImages = uploadImages;
        await prefs.setBool(_keyUploadImages, uploadImages);
      }

      if (uploadVideos != null) {
        _uploadVideos = uploadVideos;
        await prefs.setBool(_keyUploadVideos, uploadVideos);
      }
    } catch (e) {
      debugPrint('Error updating Google Sheets settings: $e');
    }
  }

  /// Get settings as map
  Map<String, dynamic> getSettings() {
    return {
      'enabled': _isEnabled,
      'webhookUrl': _webhookUrl,
      'uploadImages': _uploadImages,
      'uploadVideos': _uploadVideos,
      'isConfigured': isConfigured,
    };
  }

  /// Upload detection event to Google Sheets with retry logic
  Future<bool> uploadDetection({
    required String description,
    required DateTime timestamp,
    required double confidence,
    String? snapshotPath,
    String? videoPath,
    String? detectedType,
    String? identityName,
    double? identityConfidence,
    int? personCount,
  }) async {
    if (!isConfigured) {
      debugPrint('❌ Google Sheets not configured or disabled');
      return false;
    }

    // Check circuit breaker (prevent repeated attempts if service is down)
    if (_isCircuitBreakerOpen) {
      final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
      if (timeSinceFailure < const Duration(minutes: 5)) {
        debugPrint('⚠️ Circuit breaker open - skipping upload');
        return false;
      } else {
        // Reset circuit breaker after 5 minutes
        _isCircuitBreakerOpen = false;
        _consecutiveFailures = 0;
        debugPrint('🔄 Circuit breaker reset');
      }
    }

    // Check internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('❌ No internet connection - queuing upload for later');
      _queueFailedUpload(description, timestamp, confidence, snapshotPath, videoPath, detectedType, identityName, identityConfidence, personCount, 'No internet connection');
      return false;
    }

    int attempts = 0;
    Exception? lastError;

    // Retry loop
    while (attempts <= _maxRetries) {
      try {
        if (attempts > 0) {
          debugPrint('🔄 Retry attempt $attempts/$_maxRetries');
          await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
        }

        final success = await _performUpload(description, timestamp, confidence, snapshotPath, videoPath, detectedType, identityName, identityConfidence, personCount);
        
        if (success) {
          // Success - reset failure tracking
          _consecutiveFailures = 0;
          _lastFailureTime = null;
          debugPrint('✅ Upload successful');
          return true;
        }

        lastError = Exception('Upload returned false');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ Upload attempt ${attempts + 1} failed: $e');
      }
      
      attempts++;
    }

    // All attempts failed
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();

    // Open circuit breaker after 5 consecutive failures
    if (_consecutiveFailures >= 5) {
      _isCircuitBreakerOpen = true;
      debugPrint('🚨 Circuit breaker opened after $_consecutiveFailures consecutive failures');
    }

    // Queue for retry later
    _queueFailedUpload(description, timestamp, confidence, snapshotPath, videoPath, detectedType, identityName, identityConfidence, personCount, lastError?.toString() ?? 'Unknown error');

    // Notify error callback
    onError?.call('Failed to upload to Google Sheets after $attempts attempts: ${lastError?.toString()}');

    return false;
  }

  /// Perform the actual upload (called by retry loop)
  Future<bool> _performUpload(
    String description,
    DateTime timestamp,
    double confidence,
    String? snapshotPath,
    String? videoPath,
    String? detectedType,
    String? identityName,
    double? identityConfidence,
    int? personCount,
  ) async {
    // Prepare metadata
    final Map<String, dynamic> data = {
      'timestamp': timestamp.toIso8601String(),
      'date': '${timestamp.day}/${timestamp.month}/${timestamp.year}',
      'time': '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
      'description': description,
      'confidence': (confidence * 100).toStringAsFixed(1),
      'detectedType': detectedType ?? 'unknown',
      'identityName': identityName ?? '',
      'identityConfidence': identityConfidence != null ? (identityConfidence * 100).toStringAsFixed(1) : '',
      'personCount': personCount?.toString() ?? '',
    };

    bool imageUploadFailed = false;
    bool videoUploadFailed = false;

    // Upload snapshot image if enabled
    if (_uploadImages && snapshotPath != null && snapshotPath.isNotEmpty) {
      try {
        final snapshotFile = File(snapshotPath);
        if (await snapshotFile.exists()) {
          final fileSize = await snapshotFile.length();
          
          // Check file size (max 20MB for base64 encoding)
          if (fileSize > 20 * 1024 * 1024) {
            data['snapshotNote'] = 'Image too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)';
            debugPrint('⚠️ Snapshot too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');
          } else {
            final imageBase64 = base64Encode(await snapshotFile.readAsBytes());
            data['snapshotBase64'] = imageBase64;
            data['snapshotName'] = 'snapshot_${timestamp.millisecondsSinceEpoch}.jpg';
          }
        }
      } catch (e) {
        imageUploadFailed = true;
        data['snapshotError'] = 'Failed to read image: $e';
        debugPrint('⚠️ Failed to read snapshot: $e');
      }
    }

    // Upload video if enabled
    if (_uploadVideos && videoPath != null && videoPath.isNotEmpty) {
      try {
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          final fileSize = await videoFile.length();
          
          // Only upload if file size is reasonable (< 10MB)
          if (fileSize < 10 * 1024 * 1024) {
            final videoBase64 = base64Encode(await videoFile.readAsBytes());
            data['videoBase64'] = videoBase64;
            data['videoName'] = 'video_${timestamp.millisecondsSinceEpoch}.mp4';
          } else {
            data['videoPath'] = videoPath;
            data['videoNote'] = 'Video too large to upload automatically (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)';
          }
        }
      } catch (e) {
        videoUploadFailed = true;
        data['videoError'] = 'Failed to read video: $e';
        debugPrint('⚠️ Failed to read video: $e');
      }
    }

    // GRACEFUL DEGRADATION: Even if media uploads failed, still send metadata
    // This ensures at least the detection event is logged
    
    // Send to Google Apps Script webhook
    final response = await http
        .post(
          Uri.parse(_webhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      debugPrint('✅ Successfully uploaded to Google Sheets');
      if (imageUploadFailed || videoUploadFailed) {
        debugPrint('⚠️ Metadata logged, but some media failed to upload');
      }
      return true;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Queue a failed upload for retry later
  void _queueFailedUpload(
    String description,
    DateTime timestamp,
    double confidence,
    String? snapshotPath,
    String? videoPath,
    String? detectedType,
    String? identityName,
    double? identityConfidence,
    int? personCount,
    String error,
  ) {
    _failedUploads.add({
      'description': description,
      'timestamp': timestamp,
      'confidence': confidence,
      'snapshotPath': snapshotPath,
      'videoPath': videoPath,
      'detectedType': detectedType,
      'identityName': identityName,
      'identityConfidence': identityConfidence,
      'personCount': personCount,
      'error': error,
      'failedAt': DateTime.now(),
    });

    // Keep only last 50 failed uploads
    if (_failedUploads.length > 50) {
      _failedUploads.removeAt(0);
    }

    debugPrint('📦 Queued failed upload for retry later (Total queued: ${_failedUploads.length})');
  }

  /// Retry all failed uploads
  Future<int> retryFailedUploads() async {
    if (_failedUploads.isEmpty) return 0;

    debugPrint('🔄 Retrying ${_failedUploads.length} failed uploads...');
    int successCount = 0;

    final failedCopy = List.from(_failedUploads);
    _failedUploads.clear();

    for (final failedUpload in failedCopy) {
      final success = await uploadDetection(
        description: failedUpload['description'],
        timestamp: failedUpload['timestamp'],
        confidence: failedUpload['confidence'],
        snapshotPath: failedUpload['snapshotPath'],
        videoPath: failedUpload['videoPath'],
        detectedType: failedUpload['detectedType'],
        identityName: failedUpload['identityName'],
        identityConfidence: failedUpload['identityConfidence'],
        personCount: failedUpload['personCount'],
      );

      if (success) {
        successCount++;
      }
    }

    debugPrint('✅ Retried $successCount/${failedCopy.length} uploads successfully');
    return successCount;
  }

  /// Clear failed uploads queue
  void clearFailedUploads() {
    _failedUploads.clear();
  }

  /// Reset circuit breaker manually
  void resetCircuitBreaker() {
    _isCircuitBreakerOpen = false;
    _consecutiveFailures = 0;
    _lastFailureTime = null;
    debugPrint('🔄 Circuit breaker manually reset');
  }

  /// Test the webhook connection
  Future<bool> testWebhook() async {
    if (_webhookUrl.isEmpty) return false;

    try {
      final testData = {
        'timestamp': DateTime.now().toIso8601String(),
        'description': 'Test connection',
        'confidence': '100.0',
        'detectedType': 'test',
      };

      final response = await http
          .post(
            Uri.parse(_webhookUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(testData),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Webhook test failed: $e');
      return false;
    }
  }
}
