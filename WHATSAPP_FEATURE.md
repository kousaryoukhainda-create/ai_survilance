# WhatsApp Auto-Sharing Feature Documentation

## Overview
The AI Surveillance app now includes automatic WhatsApp sharing functionality. When movement is detected, the app can automatically send alerts to a configured WhatsApp number with snapshot images, video recordings, and detailed information.

## Features

### 1. **Auto-Share on Detection**
- Automatically sends alerts when movement is detected
- Configurable WhatsApp number
- Customizable message templates
- Option to share snapshots and/or videos

### 2. **Message Templates**
Use placeholders to create dynamic messages:
- `{date}` - Detection date
- `{time}` - Detection time  
- `{description}` - Event description (e.g., "Person detected", "John Doe detected")
- `{confidence}` - Confidence percentage

**Default Template:**
```
🔴 Security Alert

📅 Date: 11/04/2026
⏰ Time: 14:30
📝 Description: Person detected
📊 Confidence: 75.5%

📷 Snapshot attached
```

### 3. **Configuration Options**

#### Phone Number Format
- Must include country code (e.g., +91 for India)
- Examples:
  - India: +911234567890
  - US: +11234567890
  - UK: +441234567890

#### Sharing Options
- **Share Snapshots**: Include snapshot images in WhatsApp messages
- **Share Videos**: Include video recordings (opens WhatsApp with video)
- **Enable/Disable**: Toggle auto-sharing on/off without losing configuration

## Setup Instructions

### Step 1: Configure WhatsApp Number
1. Open the app
2. Go to **Settings** (tap the gear icon)
3. Scroll to **WhatsApp Integration** section
4. Toggle **Auto-Share to WhatsApp** to enable
5. Tap **WhatsApp Number**
6. Enter your WhatsApp number with country code (e.g., +911234567890)
7. Tap **Save**

### Step 2: Customize Settings (Optional)
1. **Share Snapshots**: Toggle to include snapshot images
2. **Share Videos**: Toggle to include video recordings
3. **Message Template**: Tap to customize the message format
   - Use placeholders: `{date}`, `{time}`, `{description}`, `{confidence}`
   - Example: `🚨 Alert: {description} at {time} ({confidence}%)`

### Step 3: Test the Configuration
1. Return to the main screen
2. Start monitoring
3. When movement is detected, WhatsApp will automatically open with:
   - Pre-filled message
   - Snapshot/video attached (if enabled)
4. Review and tap **Send** in WhatsApp

## How It Works

### Detection Flow
```
Movement Detected
    ↓
Snapshot/Video Captured
    ↓
Event Saved to Database
    ↓
System Notification Shown
    ↓
WhatsApp Opens (if enabled)
    ↓
Message Pre-filled + Media Attached
    ↓
User Reviews & Sends
```

### Important Notes

1. **User Interaction Required**: WhatsApp requires manual confirmation to send messages. The app opens WhatsApp with pre-filled content, but you must tap "Send".

2. **WhatsApp Must Be Installed**: The feature checks if WhatsApp is installed before attempting to share.

3. **Internet Connection Required**: WhatsApp needs an active internet connection to send messages.

4. **Media Sharing Limitations**:
   - Snapshots: Automatically attached to the message
   - Videos: Opens WhatsApp with video (may require manual attachment)
   - File size limits apply (WhatsApp's limit is typically 100MB)

5. **Background Behavior**: WhatsApp opens in the foreground. If monitoring is active, you'll need to return to the app after sending.

## Troubleshooting

### WhatsApp doesn't open
- Check if WhatsApp is installed
- Verify the phone number is correctly formatted with country code
- Ensure "Auto-Share to WhatsApp" is enabled in settings

### Message appears but no media
- Check "Share Snapshots" or "Share Videos" is enabled in settings
- Verify the snapshot/video file exists
- Check storage permissions are granted

### Error: "Cannot launch WhatsApp"
- Ensure WhatsApp is installed on your device
- Check if WhatsApp is disabled in app settings
- Try opening WhatsApp manually to verify it works

### Wrong number receives messages
- Go to Settings → WhatsApp Number
- Update to the correct number with country code
- Save and test again

## Advanced Usage

### Multiple Recipients
Currently, the app supports one WhatsApp number. To send to multiple numbers:
1. Use WhatsApp groups instead
2. Add the group number to the app
3. Messages will be sent to the group

### Custom Message Examples

**Minimal:**
```
{description} - {time}
```
Output: `Person detected - 14:30`

**Detailed:**
```
🚨 SECURITY ALERT 🚨

📍 Event: {description}
📅 Date: {date}
⏰ Time: {time}
📊 Confidence: {confidence}%

Please review immediately.
```

**Professional:**
```
Surveillance System Alert
━━━━━━━━━━━━━━━━━━━━
Type: {description}
Timestamp: {date} {time}
Confidence Level: {confidence}%
━━━━━━━━━━━━━━━━━━━━
This is an automated alert from your AI surveillance system.
```

## Technical Details

### Files Modified
- `lib/services/whatsapp_service.dart` - Core WhatsApp functionality
- `lib/services/motion_detection_service.dart` - Integration with detection
- `lib/providers/movement_provider.dart` - State management
- `lib/screens/settings_screen.dart` - UI for configuration
- `pubspec.yaml` - Added `url_launcher` and `share_plus` packages
- `android/app/src/main/AndroidManifest.xml` - Added WhatsApp package queries

### Dependencies Added
- `url_launcher: ^6.2.5` - Opens WhatsApp
- `share_plus: ^7.2.2` - Shares media files

### Permissions Required
- `INTERNET` - Already included (for WhatsApp web URLs)
- `QUERY_ALL_PACKAGES` - Not required (uses specific package queries)

## Future Enhancements (Not Implemented Yet)

1. **Multiple Recipients**: Support sending to multiple numbers
2. **Scheduled Summaries**: Send periodic summary reports
3. **Media Compression**: Auto-compress videos before sending
4. **Delivery Confirmation**: Track if messages were sent successfully
5. **WhatsApp Business API**: Integration for fully automated sending (requires Meta approval)
6. **Rich Media Messages**: Send snapshots directly without user interaction
7. **Two-Way Communication**: Receive commands via WhatsApp (e.g., "STATUS", "SNAPSHOT")

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all settings are correctly configured
3. Ensure WhatsApp is installed and working
4. Check app logs for error messages (visible in the app's error banner)

## Limitations

⚠️ **Important**: Due to WhatsApp's security policies:
- Messages cannot be sent fully automatically
- User interaction is required to confirm sending
- The app opens WhatsApp with pre-filled content
- You must manually tap "Send" in WhatsApp

For fully automated messaging, you would need:
- WhatsApp Business API account
- Meta Business verification
- Server-side integration
- Approved message templates

This is beyond the scope of a mobile app and requires enterprise-level setup.
