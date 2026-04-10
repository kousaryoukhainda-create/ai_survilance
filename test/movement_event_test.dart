import 'package:flutter_test/flutter_test.dart';
import 'package:ai_survilance/models/movement_event.dart';

void main() {
  group('MovementEvent', () {
    test('should create a MovementEvent instance', () {
      final event = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path/to/snapshot.jpg',
        confidence: 0.85,
        description: 'Movement detected',
      );

      expect(event.timestamp, isA<DateTime>());
      expect(event.snapshotPath, '/path/to/snapshot.jpg');
      expect(event.confidence, 0.85);
      expect(event.description, 'Movement detected');
    });

    test('should convert to map and back', () {
      final originalEvent = MovementEvent(
        timestamp: DateTime(2024, 1, 15, 10, 30, 0),
        snapshotPath: '/path/to/snapshot.jpg',
        confidence: 0.75,
        description: 'Test movement',
      );

      final map = originalEvent.toMap();
      final restoredEvent = MovementEvent.fromMap(map);

      expect(restoredEvent.timestamp, originalEvent.timestamp);
      expect(restoredEvent.snapshotPath, originalEvent.snapshotPath);
      expect(restoredEvent.confidence, originalEvent.confidence);
      expect(restoredEvent.description, originalEvent.description);
    });

    test('should copyWith new values', () {
      final event = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path/to/snapshot.jpg',
        confidence: 0.85,
        description: 'Movement detected',
      );

      final copiedEvent = event.copyWith(
        confidence: 0.95,
        description: 'Updated description',
      );

      expect(copiedEvent.confidence, 0.95);
      expect(copiedEvent.description, 'Updated description');
      expect(copiedEvent.timestamp, event.timestamp);
      expect(copiedEvent.snapshotPath, event.snapshotPath);
    });

    test('should handle optional videoPath', () {
      final eventWithVideo = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path/to/snapshot.jpg',
        videoPath: '/path/to/video.mp4',
        confidence: 0.85,
      );

      expect(eventWithVideo.videoPath, '/path/to/video.mp4');

      final eventWithoutVideo = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path/to/snapshot.jpg',
        confidence: 0.85,
      );

      expect(eventWithoutVideo.videoPath, isNull);
    });

    test('should handle identification fields', () {
      final event = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path/to/snapshot.jpg',
        confidence: 0.85,
        detectedType: 'person',
        identityName: 'John Doe',
        identityConfidence: 0.92,
        isFaceMatched: true,
        personCount: 1,
      );

      expect(event.detectedType, 'person');
      expect(event.identityName, 'John Doe');
      expect(event.identityConfidence, 0.92);
      expect(event.isFaceMatched, true);
      expect(event.personCount, 1);
    });

    test('should return correct type display', () {
      final personEvent = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path',
        confidence: 0.8,
        detectedType: 'person',
        identityName: 'John',
      );
      expect(personEvent.typeDisplay, '👤 John');

      final unknownPersonEvent = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path',
        confidence: 0.8,
        detectedType: 'person',
      );
      expect(unknownPersonEvent.typeDisplay, '🧑 Person');

      final vehicleEvent = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path',
        confidence: 0.8,
        detectedType: 'vehicle',
      );
      expect(vehicleEvent.typeDisplay, '🚗 Vehicle');

      final animalEvent = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path',
        confidence: 0.8,
        detectedType: 'animal',
      );
      expect(animalEvent.typeDisplay, '🐾 Animal');

      final objectEvent = MovementEvent(
        timestamp: DateTime.now(),
        snapshotPath: '/path',
        confidence: 0.8,
        detectedType: 'object',
      );
      expect(objectEvent.typeDisplay, '📦 Object');
    });
  });
}
