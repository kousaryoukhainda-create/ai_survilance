import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_survilance/screens/home_screen.dart';
import 'package:ai_survilance/services/motion_detection_service.dart';
import 'package:ai_survilance/providers/movement_provider.dart';

class MockMotionDetectionService extends MotionDetectionService {
  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> startMonitoring() async {}
  
  @override
  Future<void> stopMonitoring() async {}
  
  @override
  bool get isInitialized => true;
  
  @override
  bool get isMonitoring => false;
}

void main() {
  testWidgets('HomeScreen renders with correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MovementProvider(MockMotionDetectionService()),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Movement Detector'), findsOneWidget);
  });
}