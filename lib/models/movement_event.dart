class MovementEvent {
  final int? id;
  final DateTime timestamp;
  final String snapshotPath;
  final String? videoPath;
  final double confidence;
  final String description;
  
  // Identification fields
  final String? detectedType; // 'person', 'object', 'animal', 'vehicle'
  final String? identityName; // Name if recognized (e.g., "John Doe")
  final double? identityConfidence; // Confidence of face match
  final bool isFaceMatched; // Whether face was matched with database
  final String? objectsDetected; // JSON string of detected objects
  final int? personCount; // Number of people detected

  MovementEvent({
    this.id,
    required this.timestamp,
    required this.snapshotPath,
    this.videoPath,
    required this.confidence,
    this.description = 'Movement detected',
    this.detectedType,
    this.identityName,
    this.identityConfidence,
    this.isFaceMatched = false,
    this.objectsDetected,
    this.personCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'snapshotPath': snapshotPath,
      'videoPath': videoPath,
      'confidence': confidence,
      'description': description,
      'detectedType': detectedType,
      'identityName': identityName,
      'identityConfidence': identityConfidence,
      'isFaceMatched': isFaceMatched ? 1 : 0,
      'objectsDetected': objectsDetected,
      'personCount': personCount,
    };
  }

  factory MovementEvent.fromMap(Map<String, dynamic> map) {
    return MovementEvent(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      snapshotPath: map['snapshotPath'],
      videoPath: map['videoPath'],
      confidence: map['confidence'],
      description: map['description'],
      detectedType: map['detectedType'],
      identityName: map['identityName'],
      identityConfidence: map['identityConfidence'],
      isFaceMatched: map['isFaceMatched'] == 1,
      objectsDetected: map['objectsDetected'],
      personCount: map['personCount'],
    );
  }

  MovementEvent copyWith({
    int? id,
    DateTime? timestamp,
    String? snapshotPath,
    String? videoPath,
    double? confidence,
    String? description,
    String? detectedType,
    String? identityName,
    double? identityConfidence,
    bool? isFaceMatched,
    String? objectsDetected,
    int? personCount,
  }) {
    return MovementEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      snapshotPath: snapshotPath ?? this.snapshotPath,
      videoPath: videoPath ?? this.videoPath,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      detectedType: detectedType ?? this.detectedType,
      identityName: identityName ?? this.identityName,
      identityConfidence: identityConfidence ?? this.identityConfidence,
      isFaceMatched: isFaceMatched ?? this.isFaceMatched,
      objectsDetected: objectsDetected ?? this.objectsDetected,
      personCount: personCount ?? this.personCount,
    );
  }
  
  /// Get display type with icon
  String get typeDisplay {
    switch (detectedType) {
      case 'person':
        return identityName != null ? '👤 $identityName' : '🧑 Person';
      case 'object':
        return '📦 Object';
      case 'animal':
        return '🐾 Animal';
      case 'vehicle':
        return '🚗 Vehicle';
      default:
        return '❓ Unknown';
    }
  }
  
  /// Get identity display text
  String get identityDisplay {
    if (identityName != null && identityConfidence != null) {
      return '$identityName (${(identityConfidence * 100).toStringAsFixed(1)}% match)';
    } else if (identityName != null) {
      return identityName!;
    } else if (isFaceMatched) {
      return 'Face detected (not in database)';
    } else {
      return 'Unknown';
    }
  }
}
