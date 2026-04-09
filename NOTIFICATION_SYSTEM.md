# Movement Detector - Complete Notification System

## Notification Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Notification System Flow                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Movement Detected                                      │
│       ↓                                                 │
│  ┌────────────────────────────────────┐                │
│  │  Notification Service              │                │
│  │                                    │                │
│  │  1. System Notification            │                │
│  │     └─ Notification Tray           │                │
│  │     └─ Expandable with details     │                │
│  │     └─ Action buttons              │                │
│  │                                    │                │
│  │  2. Sound Alert                    │                │
│  │     └─ AudioPlayer beep            │                │
│  │     └─ Configurable on/off         │                │
│  │                                    │                │
│  │  3. Vibration                      │                │
│  │     └─ 500ms vibration             │                │
│  │     └─ Configurable on/off         │                │
│  │                                    │                │
│  │  4. In-App Banner                  │                │
│  │     └─ Green overlay on camera     │                │
│  │     └─ Shows confidence level      │                │
│  │                                    │                │
│  │  5. Persistent Notification        │                │
│  │     └─ "Monitoring Active"         │                │
│  │     └─ Prevents app killing        │                │
│  │     └─ Quick stop button           │                │
│  └────────────────────────────────────┘                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Notification Types

### 1. **System Notification** (When Movement Detected)

Appears in the notification tray even when app is minimized:

```
┌──────────────────────────────────────┐
│ Movement Detector         now        │
│ 📹 Movement Detected!                │
│ 85% confidence at 14:32:05           │
│ ───────────────────────────────────  │
│ [View Details] [Stop Monitoring]     │
└──────────────────────────────────────┘
```

**Features:**
- High priority notification
- Expandable with BigText style
- Shows timestamp and confidence
- Action buttons for quick actions
- Sound and vibration (configurable)
- Works when app is in background

### 2. **Persistent Notification** (When Monitoring Active)

Shows continuously while monitoring is running:

```
┌──────────────────────────────────────┐
│ Movement Detector                    │
│ 🔴 Monitoring Active                 │
│ Movement detection is running        │
│ ───────────────────────────────────  │
│ [Stop]                               │
└──────────────────────────────────────┘
```

**Features:**
- Low priority (doesn't annoy user)
- Ongoing/auto-cancel: false
- Prevents Android from killing the app
- Quick stop button
- Cannot be swiped away easily

### 3. **Sound Alert**

**Implementation:**
```dart
// Plays when movement detected
AudioPlayer player = AudioPlayer();
await player.play(AssetSource('sounds/detection_beep.mp3'));
```

**Configuration:**
- Enabled by default
- Can be toggled in Settings
- Uses AudioPlayers package

### 4. **Vibration Alert**

**Implementation:**
```dart
// Vibrates for 500ms
if (await Vibration.hasVibrator() ?? false) {
  Vibration.vibrate(duration: 500);
}
```

**Configuration:**
- Enabled by default
- Can be toggled in Settings
- Checks if device has vibrator first

### 5. **In-App Banner**

Shows on the home screen when app is open:

```
┌─────────────────────────────────┐
│  [Camera Preview]               │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🔴 Movement Detected!     │  │
│  │    85.0% confidence       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

## Settings Screen

Access via Settings icon (⚙️) in app bar.

### Available Settings:

| Setting | Default | Description |
|---------|---------|-------------|
| **System Notifications** | ✅ ON | Show notifications in system tray |
| **Sound Alerts** | ✅ ON | Play sound when movement detected |
| **Vibration** | ✅ ON | Vibrate device on detection |
| **Persistent Notification** | ✅ ON | Show "Monitoring Active" notification |

### How to Change Settings:

1. Tap **Settings** icon (⚙️) in app bar
2. Toggle switches on/off
3. Changes apply immediately
4. Tap **Reset to Defaults** to restore

## Required Permissions

### Android Permissions Added:

```xml
<!-- Notification permission (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Vibration permission -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Foreground service permission -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### Permission Request Flow:

```
App Launch
    ↓
Check All Permissions
    ↓
┌─────────────────────────────────┐
│ Permissions Needed:             │
│                                 │
│ ✅ Camera                       │
│ ✅ Storage                      │
│ ✅ Microphone                   │
│ ✅ Notifications (NEW)          │
│ ✅ Vibration (NEW)              │
└─────────────────────────────────┘
    ↓
User Grants All
    ↓
App Starts
```

## Notification Channels (Android)

### Channel 1: Movement Detections
- **ID:** `movement_detection_channel`
- **Name:** Movement Detections
- **Importance:** HIGH
- **Sound:** Enabled (configurable)
- **Vibration:** Enabled (configurable)
- **User Configurable:** Yes (in Android settings)

### Channel 2: Monitoring Service
- **ID:** `persistent_monitoring_channel`
- **Name:** Monitoring Service
- **Importance:** LOW
- **Sound:** Disabled
- **Vibration:** Disabled
- **User Configurable:** Yes (in Android settings)

## Code Integration

### Motion Detection Service Integration:

```dart
// In motion_detection_service.dart

// When monitoring starts
Future<void> startMonitoring() async {
  _isMonitoring = true;
  
  // Show persistent notification
  await _notificationService.showPersistentNotification();
  
  // Start detection...
}

// When movement detected
Future<void> _handleMovementDetected(...) async {
  // Save to database...
  
  // Show system notification
  await _notificationService.showMovementNotification(event);
  
  // Notify UI...
}

// When monitoring stops
Future<void> stopMonitoring() async {
  _isMonitoring = false;
  
  // Hide persistent notification
  await _notificationService.hidePersistentNotification();
}
```

### Provider Integration:

```dart
// In movement_provider.dart

// Update settings
Future<void> updateNotificationSettings({
  bool? enableSystemNotification,
  bool? enableSound,
  bool? enableVibration,
  bool? enablePersistentNotification,
}) async {
  _notificationService.updateSettings(...);
  // Update local state
  notifyListeners();
}
```

## Notification Actions

### Action Buttons:

1. **View Details**
   - Opens movement detail screen
   - Shows full snapshot
   - Displays confidence and timestamp

2. **Stop Monitoring**
   - Immediately stops motion detection
   - Hides persistent notification
   - Updates UI state

### Handling Actions:

```dart
// In notification_service.dart
void _onNotificationTapped(NotificationResponse response) {
  final payload = response.payload;
  
  if (payload == 'movement_${id}') {
    // Navigate to movement details
  } else if (payload == 'persistent_monitoring') {
    // Stop monitoring
  }
}
```

## Customization

### Change Notification Sound:

```dart
// In notification_service.dart - showMovementNotification()
final androidDetails = AndroidNotificationDetails(
  _movementChannelId,
  'Movement Detections',
  sound: RawResourceAndroidNotificationSound('custom_sound'),
  // ...
);
```

Add sound file to: `android/app/src/main/res/raw/custom_sound.mp3`

### Change Vibration Duration:

```dart
// In notification_service.dart - _vibrate()
Vibration.vibrate(duration: 1000); // 1 second instead of 500ms
```

### Adjust Notification Priority:

```dart
// Change importance level
importance: Importance.max      // Shows as heads-up
importance: Importance.high     // Default high
importance: Importance.default  // Normal
importance: Importance.low      // Quiet
```

## Testing Notifications

### Test Checklist:

- [ ] System notification appears on movement
- [ ] Notification expands with details
- [ ] Sound plays on detection
- [ ] Device vibrates on detection
- [ ] Persistent notification shows when monitoring
- [ ] Persistent notification cannot be swiped
- [ ] Stop button works in persistent notification
- [ ] Settings toggles work
- [ ] Notifications work when app is minimized
- [ ] Notifications work when screen is locked

### Manual Testing:

```bash
# 1. Build and run
flutter run

# 2. Grant all permissions

# 3. Start monitoring
#    → Check persistent notification appears

# 4. Wave hand in front of camera
#    → Check system notification appears
#    → Check sound plays
#    → Check device vibrates

# 5. Minimize app
#    → Wave hand again
#    → Check notification still appears

# 6. Open settings
#    → Toggle sound off
#    → Test again (no sound)
```

## Troubleshooting

### Notifications Not Showing:

1. **Check Permission:**
   - Go to Android Settings → Apps → Movement Detector → Permissions
   - Ensure "Notifications" is allowed

2. **Check Channel Settings:**
   - Long-press notification
   - Tap "Settings"
   - Ensure channel is not blocked

3. **Check App Settings:**
   - Open app → Settings
   - Ensure "System Notifications" is ON

### Sound Not Playing:

1. Check device is not on silent mode
2. Check "Sound Alerts" is ON in app settings
3. Verify audio file exists in assets

### Vibration Not Working:

1. Check device has vibrator hardware
2. Check "Vibration" is ON in app settings
3. Check Android permission is granted

## Future Enhancements

- [ ] Custom notification sounds per confidence level
- [ ] Quiet hours (no notifications at night)
- [ ] Email notifications
- [ ] SMS alerts for high-confidence detections
- [ ] Push notifications to other devices
- [ ] Notification scheduling
- [ ] Group notifications (batch alerts)
- [ ] Wearable device integration
