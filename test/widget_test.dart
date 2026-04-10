import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_survilance/main.dart';
import 'package:ai_survilance/services/motion_detection_service.dart';
import 'package:ai_survilance/providers/movement_provider.dart';

void main() {
  testWidgets('App renders HomeScreen with correct title', (WidgetTester tester) async {
    // Build our app with required providers
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MovementProvider(MotionDetectionService()),
        child: const MyApp(),
      ),
    );

    // Use explicit pump calls instead of pumpAndSettle to avoid timeout
    // from ongoing async operations (camera init, permission checks, etc.)
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Verify the app renders the HomeScreen with correct title
    expect(find.text('Movement Detector'), findsOneWidget);
  });
}
