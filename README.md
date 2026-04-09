# Movement Detector - Android App

A Flutter-based Android application that detects and records person movement using the device's camera. The app continuously monitors the camera feed, detects motion using frame-by-frame comparison, and saves movement events with snapshots.

## Features

- **Real-time Motion Detection**: Uses camera frame comparison to detect movement
- **Automatic Snapshot Capture**: Saves images when movement is detected
- **Video Recording**: Manual video recording capability
- **Movement History**: Stores all movement events with timestamps
- **Confidence Scoring**: Shows detection confidence levels
- **Beautiful UI**: Material Design 3 with light/dark theme support
- **Permission Management**: Handles all required permissions gracefully

## Architecture

```
lib/
├── main.dart                           # App entry point with permission handling
├── models/
│   └── movement_event.dart            # Data model for movement events
├── services/
│   ├── motion_detection_service.dart  # Core motion detection logic
│   ├── database_helper.dart           # SQLite database operations
│   └── permission_service.dart        # Permission handling
├── providers/
│   └── movement_provider.dart         # State management with Provider
├── screens/
│   ├── home_screen.dart               # Main camera and monitoring screen
│   ├── movement_history_screen.dart   # History list view
│   └── movement_detail_screen.dart    # Event detail view
└── widgets/
    └── permission_dialog.dart         # Permission request dialog
```

## How It Works

### Motion Detection Algorithm

1. **Frame Capture**: Captures frames from the camera at 500ms intervals
2. **Image Processing**: Resizes frames to 160x120 for efficient processing
3. **Frame Comparison**: Compares current frame with previous frame
4. **Pixel Difference Calculation**: 
   - Converts pixels to grayscale
   - Calculates difference between corresponding pixels
   - Counts pixels exceeding threshold (25.0)
5. **Motion Score**: Calculates percentage of different pixels
6. **Detection Trigger**: If motion score > 30%, triggers movement event

### Data Storage

- **SQLite Database**: Stores movement event metadata
- **File System**: Saves snapshot images in app documents directory
- **Event Data**: Timestamp, snapshot path, confidence, description

## Installation

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Android Studio or Android SDK
- An Android device or emulator with camera support

### Setup Steps

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Check Android Setup**:
   ```bash
   flutter doctor
   ```

3. **Run on Device**:
   ```bash
   flutter run
   ```

### Build APK

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Usage

### First Launch

1. Grant required permissions when prompted:
   - Camera access
   - Storage access
   - Microphone access (for video recording)

### Main Screen

- **Camera Preview**: Shows live camera feed
- **Start/Stop Button**: Begin or end motion monitoring
- **Record Button**: Manually start/stop video recording
- **Status Indicator**: Shows monitoring state
- **Detection Counter**: Displays total detections
- **Last Event Time**: Shows time of last detected movement

### Monitoring

1. Tap **Start** to begin motion detection
2. The app will automatically detect movement
3. When movement is detected:
   - A notification appears on screen
   - A snapshot is saved
   - The event is logged to the database
   - The counter increments

### Viewing History

1. Tap the **History** icon in the app bar
2. Browse all detected movement events
3. View snapshots and confidence levels
4. Tap an event to see details
5. Delete individual events or clear all

### Movement Details

- Full-size snapshot view
- Confidence level with progress indicator
- Exact timestamp
- File path information
- Options to share or view full screen

## Configuration

### Motion Detection Parameters

You can adjust sensitivity in `motion_detection_service.dart`:

```dart
// Lower values = more sensitive
final double motionThreshold = 30.0;              // Threshold to trigger detection (0-100)
final double pixelDifferenceThreshold = 25.0;     // Pixel difference threshold (0-255)
```

### Frame Capture Rate

```dart
// Adjust in startMonitoring()
_detectionTimer = Timer.periodic(
  const Duration(milliseconds: 500), // Change interval here
  (_) => _captureAndAnalyzeFrame(),
);
```

### Image Processing Resolution

```dart
// Adjust in _captureAndAnalyzeFrame()
final processedFrame = img.copyResize(
  currentFrame,
  width: 160,   // Change processing width
  height: 120,  // Change processing height
);
```

## Dependencies

- **camera**: Camera access and video streaming
- **image**: Image processing and frame comparison
- **sqflite**: Local database storage
- **path_provider**: File system paths
- **path**: Path manipulation
- **permission_handler**: Runtime permissions
- **provider**: State management
- **video_player**: Video playback
- **image_picker**: Image selection
- **intl**: Date/time formatting

## Permissions

The app requires the following Android permissions:

- `CAMERA`: Access camera for motion detection
- `WRITE_EXTERNAL_STORAGE`: Save snapshots and recordings
- `READ_EXTERNAL_STORAGE`: Access saved files
- `RECORD_AUDIO`: Record audio with videos
- `INTERNET`: Future features

## Project Structure

```
ai_survilance/
├── android/                          # Android-specific files
├── lib/                              # Flutter source code
│   ├── main.dart
│   ├── models/
│   ├── services/
│   ├── providers/
│   ├── screens/
│   └── widgets/
├── test/                             # Unit tests
├── pubspec.yaml                      # Dependencies
└── README.md                         # This file
```

## Building for Production

### Generate Release APK

```bash
flutter build apk --release
```

### Generate App Bundle (for Play Store)

```bash
flutter build appbundle
```

### Optimize APK Size

```bash
flutter build apk --split-per-abi
```

## Troubleshooting

### Camera Not Working

- Ensure camera permissions are granted
- Check that the device has a camera
- Try restarting the app

### Motion Detection Too Sensitive/Not Sensitive Enough

- Adjust `motionThreshold` and `pixelDifferenceThreshold` in `motion_detection_service.dart`
- Higher values = less sensitive
- Lower values = more sensitive

### App Crashes on Startup

- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app

### Snapshots Not Saving

- Check storage permissions
- Ensure sufficient storage space
- Check app documents directory

## Future Enhancements

- [ ] Push notifications on movement detection
- [ ] Cloud storage integration
- [ ] Email/SMS alerts
- [ ] Scheduled monitoring
- [ ] Person detection using ML
- [ ] Multiple camera support
- [ ] Export movement history to CSV
- [ ] Video playback from history
- [ ] Settings screen for sensitivity adjustment
- [ ] Night mode scheduling

## Performance Considerations

- Frame processing is done at reduced resolution (160x120) for speed
- Detection runs at 2 FPS (500ms intervals) to balance performance and accuracy
- Images are processed synchronously to prevent frame drops
- Database queries are limited to 50 records by default

## Security Notes

- All data is stored locally on the device
- No network transmission of snapshots or data
- Database is stored in app's private directory
- Consider implementing encryption for sensitive deployments

## License

This project is for educational and personal use.

## Support

For issues or questions, please check:
- Flutter documentation: https://flutter.dev/docs
- Camera package: https://pub.dev/packages/camera
- Image package: https://pub.dev/packages/image
