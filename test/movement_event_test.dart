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
  });
}
