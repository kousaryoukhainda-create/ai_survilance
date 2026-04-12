import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_survilance/services/motion_detection_service.dart';

void main() {
  group('DetectionBox', () {
    test('should create DetectionBox with correct values', () {
      const box = DetectionBox(
        x: 100.0,
        y: 50.0,
        width: 200.0,
        height: 150.0,
        label: 'Person',
        confidence: 0.95,
      );

      expect(box.x, 100.0);
      expect(box.y, 50.0);
      expect(box.width, 200.0);
      expect(box.height, 150.0);
      expect(box.label, 'Person');
      expect(box.confidence, 0.95);
    });

    test('should handle zero coordinates', () {
      const box = DetectionBox(
        x: 0.0,
        y: 0.0,
        width: 100.0,
        height: 100.0,
        label: 'Car',
        confidence: 0.8,
      );

      expect(box.x, 0.0);
      expect(box.y, 0.0);
    });
  });

  group('DetectionBoxPainter', () {
    testWidgets('should paint bounding boxes', (tester) async {
      const boxes = [
        DetectionBox(
          x: 0.0,
          y: 0.0,
          width: 100.0,
          height: 100.0,
          label: 'Person',
          confidence: 0.9,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: CustomPaint(
                painter: DetectionBoxPainter(boxes),
                child: Container(),
              ),
            ),
          ),
        ),
      );

      // Verify the CustomPaint widget is rendered
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should handle multiple boxes', (tester) async {
      const boxes = [
        DetectionBox(
          x: 0.0,
          y: 0.0,
          width: 100.0,
          height: 100.0,
          label: 'Person',
          confidence: 0.9,
        ),
        DetectionBox(
          x: 150.0,
          y: 50.0,
          width: 80.0,
          height: 80.0,
          label: 'Car',
          confidence: 0.85,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: CustomPaint(
                painter: DetectionBoxPainter(boxes),
                child: Container(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should repaint when boxes change', (tester) async {
      const boxes1 = [
        DetectionBox(
          x: 0.0,
          y: 0.0,
          width: 100.0,
          height: 100.0,
          label: 'Person',
          confidence: 0.9,
        ),
      ];

      const boxes2 = [
        DetectionBox(
          x: 50.0,
          y: 50.0,
          width: 150.0,
          height: 150.0,
          label: 'Car',
          confidence: 0.8,
        ),
      ];

      final painter1 = DetectionBoxPainter(boxes1);
      final painter2 = DetectionBoxPainter(boxes2);

      expect(painter1.shouldRepaint(painter2), true);

      const sameBoxes = [
        DetectionBox(
          x: 0.0,
          y: 0.0,
          width: 100.0,
          height: 100.0,
          label: 'Person',
          confidence: 0.9,
        ),
      ];

      final painter3 = DetectionBoxPainter(sameBoxes);
      expect(painter1.shouldRepaint(painter3), false);
    });
  });
}
