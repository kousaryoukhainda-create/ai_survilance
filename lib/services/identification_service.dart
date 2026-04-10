import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'database_helper.dart';

class IdentificationService {
  static final IdentificationService instance = IdentificationService._init();
  
  // ML Kit detectors
  late final ObjectDetector _objectDetector;
  late final FaceDetector _faceDetector;
  
  // Face recognition database
  final List<KnownFace> _knownFaces = [];
  
  // Settings
  bool _enablePersonDetection = true;
  bool _enableFaceRecognition = true;
  bool _enableObjectClassification = true;
  double _faceMatchThreshold = 0.6;
  
  // State
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  bool get enablePersonDetection => _enablePersonDetection;
  bool get enableFaceRecognition => _enableFaceRecognition;
  bool get enableObjectClassification => _enableObjectClassification;

  IdentificationService._init();

  /// Initialize ML Kit detectors
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize object detector with default options
      final options = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);

      // Initialize face detector
      final faceOptions = FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      );
      _faceDetector = FaceDetector(options: faceOptions);

      // Load known faces from database
      await _loadKnownFaces();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing identification service: $e');
      _isInitialized = false;
    }
  }

  /// Load known faces from database
  Future<void> _loadKnownFaces() async {
    try {
      final persons = await DatabaseHelper.instance.getAllPersons();
      _knownFaces.clear();
      
      for (final person in persons) {
        _knownFaces.add(KnownFace(
          id: person['id'],
          name: person['name'],
          faceEncoding: person['faceEncoding'],
          photoPath: person['photoPath'],
        ));
      }
    } catch (e) {
      debugPrint('Error loading known faces: $e');
    }
  }

  /// Analyze frame for persons and objects
  Future<IdentificationResult> analyzeFrame(InputImage inputImage) async {
    if (!_isInitialized) {
      return IdentificationResult(
        detectedType: 'unknown',
        personCount: 0,
        objects: [],
        faces: [],
        identityName: null,
        identityConfidence: null,
        isFaceMatched: false,
      );
    }

    final result = IdentificationResult(
      detectedType: 'unknown',
      personCount: 0,
      objects: [],
      faces: [],
    );

    try {
      // Run object detection
      if (_enablePersonDetection || _enableObjectClassification) {
        final objects = await _detectObjects(inputImage);
        result.objects = objects;
        
        // Count persons
        result.personCount = objects.where((obj) => 
          obj.trackingId != null && 
          _isPerson(obj.labels)
        ).length;
        
        // Determine primary detected type
        if (result.personCount > 0) {
          result.detectedType = 'person';
        } else if (objects.isNotEmpty) {
          result.detectedType = _classifyObjects(objects);
        }
      }

      // Run face detection and recognition
      if (_enableFaceRecognition && result.personCount > 0) {
        final faces = await _detectFaces(inputImage);
        result.faces = faces;
        
        // Try to match faces with known persons
        if (faces.isNotEmpty) {
          final match = await _matchFace(faces.first);
          if (match != null) {
            result.identityName = match.name;
            result.identityConfidence = match.confidence;
            result.isFaceMatched = true;
            
            // Update last seen
            await DatabaseHelper.instance.updatePersonLastSeen(match.faceId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error analyzing frame: $e');
    }

    return result;
  }

  /// Detect objects in the image
  Future<List<DetectedObject>> _detectObjects(InputImage inputImage) async {
    try {
      final objects = await _objectDetector.processImage(inputImage);
      return objects;
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  /// Detect faces in the image
  Future<List<Face>> _detectFaces(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      return [];
    }
  }

  /// Check if detected object is a person
  bool _isPerson(List<Label> labels) {
    for (final label in labels) {
      final text = label.text.toLowerCase();
      if (text.contains('person') || 
          text.contains('human') || 
          text.contains('people')) {
        return true;
      }
    }
    return false;
  }

  /// Classify the primary object type
  String _classifyObjects(List<DetectedObject> objects) {
    if (objects.isEmpty) return 'unknown';
    
    // Get the object with highest confidence
    final primaryObject = objects.reduce((a, b) {
      final aConf = a.labels.isEmpty ? 0.0 : a.labels.first.confidence;
      final bConf = b.labels.isEmpty ? 0.0 : b.labels.first.confidence;
      return aConf > bConf ? a : b;
    });
    
    if (primaryObject.labels.isEmpty) return 'unknown';
    
    final primaryLabel = primaryObject.labels.first.text.toLowerCase();
    
    // Classify into categories
    if (primaryLabel.contains('car') || 
        primaryLabel.contains('vehicle') ||
        primaryLabel.contains('truck')) {
      return 'vehicle';
    } else if (primaryLabel.contains('dog') || 
               primaryLabel.contains('cat') ||
               primaryLabel.contains('animal')) {
      return 'animal';
    } else {
      return 'object';
    }
  }

  /// Match detected face with known faces
  Future<FaceMatch?> _matchFace(Face face) async {
    if (_knownFaces.isEmpty) return null;
    
    // Extract face features (simplified approach)
    // In production, you would use a proper face recognition model
    final faceFeatures = _extractFaceFeatures(face);
    
    double bestConfidence = 0.0;
    KnownFace? bestMatch;
    
    for (final knownFace in _knownFaces) {
      final confidence = _calculateSimilarity(faceFeatures, knownFace.faceEncoding);
      
      if (confidence > bestConfidence && confidence >= _faceMatchThreshold) {
        bestConfidence = confidence;
        bestMatch = knownFace;
      }
    }
    
    if (bestMatch != null) {
      return FaceMatch(
        faceId: bestMatch.id,
        name: bestMatch.name,
        confidence: bestConfidence,
      );
    }
    
    return null;
  }

  /// Extract simplified face features
  /// Note: This is a simplified approach. Production should use proper face recognition
  String _extractFaceFeatures(Face face) {
    // Create a feature vector from face properties
    final features = [
      face.boundingBox.width,
      face.boundingBox.height,
      face.headEulerAngleX ?? 0,
      face.headEulerAngleY ?? 0,
      face.headEulerAngleZ ?? 0,
      face.smilingProbability ?? 0,
      face.leftEyeOpenProbability ?? 0,
      face.rightEyeOpenProbability ?? 0,
    ];
    
    return jsonEncode(features);
  }

  /// Calculate similarity between face features
  double _calculateSimilarity(String features1, String features2) {
    try {
      final list1 = List<double>.from(jsonDecode(features1));
      final list2 = List<double>.from(jsonDecode(features2));
      
      if (list1.length != list2.length) return 0.0;
      
      // Calculate cosine similarity
      double dotProduct = 0;
      double norm1 = 0;
      double norm2 = 0;
      
      for (int i = 0; i < list1.length; i++) {
        dotProduct += list1[i] * list2[i];
        norm1 += list1[i] * list1[i];
        norm2 += list2[i] * list2[i];
      }
      
      if (norm1 == 0 || norm2 == 0) return 0.0;
      
      return dotProduct / (norm1.sqrt() * norm2.sqrt());
    } catch (e) {
      return 0.0;
    }
  }

  /// Register a new person with face photo
  Future<int> registerPerson({
    required String name,
    required String photoPath,
    required Face face,
    String? notes,
  }) async {
    final faceEncoding = _extractFaceFeatures(face);
    
    final id = await DatabaseHelper.instance.addPerson(
      name: name,
      faceEncoding: faceEncoding,
      photoPath: photoPath,
      notes: notes,
    );
    
    // Reload known faces
    await _loadKnownFaces();
    
    return id;
  }

  /// Get all known persons
  Future<List<Map<String, dynamic>>> getKnownPersons() async {
    return await DatabaseHelper.instance.getAllPersons();
  }

  /// Delete a known person
  Future<void> deleteKnownPerson(int id) async {
    await DatabaseHelper.instance.deletePerson(id);
    await _loadKnownFaces();
  }

  /// Update identification settings
  void updateSettings({
    bool? enablePersonDetection,
    bool? enableFaceRecognition,
    bool? enableObjectClassification,
    double? faceMatchThreshold,
  }) {
    if (enablePersonDetection != null) {
      _enablePersonDetection = enablePersonDetection;
    }
    if (enableFaceRecognition != null) {
      _enableFaceRecognition = enableFaceRecognition;
    }
    if (enableObjectClassification != null) {
      _enableObjectClassification = enableObjectClassification;
    }
    if (faceMatchThreshold != null) {
      _faceMatchThreshold = faceMatchThreshold;
    }
  }

  /// Get current settings
  Map<String, dynamic> getSettings() {
    return {
      'enablePersonDetection': _enablePersonDetection,
      'enableFaceRecognition': _enableFaceRecognition,
      'enableObjectClassification': _enableObjectClassification,
      'faceMatchThreshold': _faceMatchThreshold,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _objectDetector.close();
    await _faceDetector.close();
  }
}

/// Result of frame analysis
class IdentificationResult {
  String detectedType;
  int personCount;
  List<DetectedObject> objects;
  List<Face> faces;
  String? identityName;
  double? identityConfidence;
  bool isFaceMatched;

  IdentificationResult({
    required this.detectedType,
    required this.personCount,
    required this.objects,
    required this.faces,
    this.identityName,
    this.identityConfidence,
    this.isFaceMatched = false,
  });
  
  /// Get list of detected object labels
  List<String> getObjectLabels() {
    return objects.expand((obj) => 
      obj.labels.map((label) => '${label.text} (${(label.confidence * 100).toStringAsFixed(0)}%)')
    ).toList();
  }
  
  /// Get summary text for notification
  String get summaryText {
    if (isFaceMatched && identityName != null) {
      return '$identityName detected';
    } else if (personCount > 0) {
      return '$personCount person${personCount > 1 ? 's' : ''} detected';
    } else if (objects.isNotEmpty) {
      final primaryLabel = objects.first.labels.first.text;
      return '$primaryLabel detected';
    }
    return 'Movement detected';
  }
}

/// Known face in database
class KnownFace {
  final int id;
  final String name;
  final String faceEncoding;
  final String photoPath;

  KnownFace({
    required this.id,
    required this.name,
    required this.faceEncoding,
    required this.photoPath,
  });
}

/// Face match result
class FaceMatch {
  final int faceId;
  final String name;
  final double confidence;

  FaceMatch({
    required this.faceId,
    required this.name,
    required this.confidence,
  });
}

extension on double {
  double sqrt() {
    if (this < 0) return double.nan;
    if (this == 0) return 0;
    
    double guess = this / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}
