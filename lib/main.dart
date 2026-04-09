import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/motion_detection_service.dart';
import 'services/permission_service.dart';
import 'services/notification_service.dart';
import 'providers/movement_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/permission_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service first
  await NotificationService.instance.initialize();
  
  // Create services
  final motionService = MotionDetectionService();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => MovementProvider(motionService),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movement Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const PermissionWrapper(),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _permissionsGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionService.instance.areAllPermissionsGranted();
    setState(() {
      _permissionsGranted = granted;
      _checkingPermissions = false;
    });
  }

  void _onPermissionsGranted() {
    setState(() {
      _permissionsGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_permissionsGranted) {
      return PermissionDialog(onPermissionsGranted: _onPermissionsGranted);
    }

    return const HomeScreen();
  }
}
