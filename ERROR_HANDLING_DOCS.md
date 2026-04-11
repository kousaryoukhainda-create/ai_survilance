# Google Sheets Error Handling Documentation

## Overview
The Google Sheets upload feature includes **comprehensive error handling** to ensure reliability and prevent data loss even when uploads fail.

---

## Error Handling Mechanisms

### 1. ✅ **Retry Mechanism with Exponential Backoff**

**What it does:**
- Automatically retries failed uploads up to 3 times (configurable)
- Waits longer between each retry (2s, 4s, 6s) to avoid overwhelming the server

**Implementation:**
```dart
// Retry loop
while (attempts <= _maxRetries) {
  if (attempts > 0) {
    await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
  }
  // Attempt upload...
  attempts++;
}
```

**Why it matters:**
- Transient network issues are automatically recovered
- No manual intervention needed
- Prevents spamming the server with rapid retries

---

### 2. ✅ **Circuit Breaker Pattern**

**What it does:**
- Stops trying after 5 consecutive failures
- Waits 5 minutes before trying again
- Prevents wasting resources when service is completely down

**Implementation:**
```dart
// Open circuit breaker after 5 consecutive failures
if (_consecutiveFailures >= 5) {
  _isCircuitBreakerOpen = true;
  debugPrint('🚨 Circuit breaker opened');
}

// Auto-reset after 5 minutes
if (_isCircuitBreakerOpen) {
  final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
  if (timeSinceFailure >= const Duration(minutes: 5)) {
    _isCircuitBreakerOpen = false; // Reset
  }
}
```

**Why it matters:**
- Prevents battery drain from continuous failed attempts
- Gives the service time to recover
- Automatically resumes when service is back

---

### 3. ✅ **Internet Connectivity Check**

**What it does:**
- Checks if device has internet BEFORE attempting upload
- Queues failed uploads for later if offline
- No wasted attempts when clearly offline

**Implementation:**
```dart
final connectivityResult = await Connectivity().checkConnectivity();
if (connectivityResult == ConnectivityResult.none) {
  debugPrint('❌ No internet connection - queuing upload for later');
  _queueFailedUpload(...);
  return false;
}
```

**Why it matters:**
- Saves battery and resources
- Works gracefully when offline
- Automatically retries when connection returns

---

### 4. ✅ **Failed Upload Queue**

**What it does:**
- Stores failed uploads in memory (up to 50)
- Allows manual retry when issues are resolved
- No data loss even when uploads fail

**Implementation:**
```dart
void _queueFailedUpload(...) {
  _failedUploads.add({
    'description': description,
    'timestamp': timestamp,
    'error': error,
    'failedAt': DateTime.now(),
    // ... all data needed for retry
  });
  
  // Keep only last 50
  if (_failedUploads.length > 50) {
    _failedUploads.removeAt(0);
  }
}

// Manual retry
Future<int> retryFailedUploads() async {
  // Retry all queued uploads
}
```

**Why it matters:**
- No detection events are lost
- User can manually retry when convenient
- Provides visibility into what failed

---

### 5. ✅ **Graceful Degradation**

**What it does:**
- If image/video upload fails, STILL sends metadata to Google Sheets
- Ensures at least the detection event is logged
- Adds error notes to the spreadsheet for failed media

**Implementation:**
```dart
// Upload snapshot image if enabled
if (_uploadImages && snapshotPath != null) {
  try {
    // Try to read and encode image
    data['snapshotBase64'] = imageBase64;
  } catch (e) {
    // Image failed - but continue anyway
    data['snapshotError'] = 'Failed to read image: $e';
  }
}

// GRACEFUL DEGRADATION: Even if media uploads failed, still send metadata
final response = await http.post(...);
```

**Why it matters:**
- Partial data is better than no data
- Detection event is still logged with timestamp
- User can see what happened from error notes

---

### 6. ✅ **File Size Validation**

**What it does:**
- Checks file sizes BEFORE attempting upload
- Images: Max 20MB (base64 encoding limit)
- Videos: Max 10MB (automatic upload limit)
- Prevents crashes from encoding huge files

**Implementation:**
```dart
// Check file size (max 20MB for base64 encoding)
if (fileSize > 20 * 1024 * 1024) {
  data['snapshotNote'] = 'Image too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)';
} else {
  final imageBase64 = base64Encode(await snapshotFile.readAsBytes());
  data['snapshotBase64'] = imageBase64;
}
```

**Why it matters:**
- Prevents OutOfMemoryError crashes
- Provides clear feedback about file size issues
- Still logs the event with a note

---

### 7. ✅ **HTTP Timeout**

**What it does:**
- 30-second timeout for webhook requests
- Prevents hanging connections
- Fast failure instead of indefinite waiting

**Implementation:**
```dart
final response = await http
    .post(Uri.parse(_webhookUrl), ...)
    .timeout(const Duration(seconds: 30));
```

**Why it matters:**
- App doesn't freeze waiting for slow server
- Predictable failure behavior
- Retry can happen quickly

---

### 8. ✅ **Error Callback**

**What it does:**
- Notifies the app when uploads fail
- Allows UI to show error to user
- Enables custom error handling

**Implementation:**
```dart
// Service definition
Function(String error)? onError;

// Usage
onError?.call('Failed to upload after $attempts attempts: $lastError');
```

**Why it matters:**
- User gets feedback about issues
- App can show error banner/notification
- Enables debugging

---

### 9. ✅ **Detailed Error Logging**

**What it does:**
- Logs all errors with context
- Uses emoji indicators for easy reading
- Tracks consecutive failures

**Implementation:**
```dart
debugPrint('❌ Google Sheets not configured');
debugPrint('🔄 Retry attempt 2/3');
debugPrint('✅ Upload successful');
debugPrint('⚠️ Snapshot too large: 25.3MB');
debugPrint('🚨 Circuit breaker opened after 5 consecutive failures');
```

**Why it matters:**
- Easy debugging from logs
- Clear status indicators
- Helps identify patterns

---

## Error Scenarios & Responses

| Scenario | What Happens | User Impact |
|----------|--------------|-------------|
| **No internet** | Upload queued, retry later | None - automatic |
| **Server timeout** | Retry up to 3 times | None - automatic |
| **Server error (500)** | Retry + circuit breaker | None - automatic |
| **Image file missing** | Log metadata only, add error note | Partial data logged |
| **Image too large** | Skip image, log metadata + note | Partial data logged |
| **Video too large** | Skip video, log metadata + note | Partial data logged |
| **5 consecutive failures** | Circuit breaker opens, wait 5 min | Delayed logging |
| **Invalid webhook URL** | All retries fail, queued | Manual fix needed |
| **Google Drive full** | Uploads fail, queued | Free up space |

---

## Manual Recovery Options

### View Failed Uploads
```dart
final failedUploads = googleSheetsService.failedUploads;
print('Failed uploads: ${failedUploads.length}');
for (final upload in failedUploads) {
  print('Error: ${upload['error']}');
  print('Failed at: ${upload['failedAt']}');
}
```

### Retry Failed Uploads
```dart
final successCount = await googleSheetsService.retryFailedUploads();
print('Retried $successCount uploads successfully');
```

### Clear Failed Queue
```dart
googleSheetsService.clearFailedUploads();
```

### Reset Circuit Breaker
```dart
googleSheetsService.resetCircuitBreaker();
```

---

## Configuration Options

### Max Retries (Default: 3)
```dart
// In settings - allow user to configure
int _maxRetries = 3;
```

### Circuit Breaker Threshold (Default: 5)
```dart
// Opens after 5 consecutive failures
if (_consecutiveFailures >= 5) {
  _isCircuitBreakerOpen = true;
}
```

### Circuit Breaker Cooldown (Default: 5 minutes)
```dart
// Auto-reset after 5 minutes
if (timeSinceFailure >= const Duration(minutes: 5)) {
  _isCircuitBreakerOpen = false;
}
```

---

## Best Practices

### ✅ DO
- Monitor failed uploads queue size
- Check error logs for patterns
- Retry failed uploads when convenient
- Use error callback to show user feedback
- Test webhook URL before enabling

### ❌ DON'T
- Ignore repeated failures (indicates configuration issue)
- Retry too frequently (respect circuit breaker)
- Disable error logging (needed for debugging)
- Assume uploads always succeed (check status)

---

## Troubleshooting

### "No internet connection"
- **Cause**: Device is offline
- **Solution**: Upload queued automatically, will retry when online

### "Circuit breaker open"
- **Cause**: 5+ consecutive failures
- **Solution**: Wait 5 minutes, or manually reset circuit breaker

### "Failed to read image/video"
- **Cause**: File deleted or corrupted
- **Solution**: Metadata still logged, check file paths

### "HTTP 404"
- **Cause**: Invalid webhook URL
- **Solution**: Reconfigure webhook URL in settings

### "HTTP 500"
- **Cause**: Google Apps Script error
- **Solution**: Check script logs, redeploy if needed

### "Image/Video too large"
- **Cause**: File exceeds size limit
- **Solution**: Reduce camera resolution or disable media upload

---

## Monitoring & Alerts

### Check Upload Health
```dart
// Get consecutive failure count
final failures = googleSheetsService.consecutiveFailures;
if (failures > 3) {
  print('⚠️ Multiple failures detected');
}

// Check if circuit breaker is open
if (googleSheetsService.isCircuitBreakerOpen) {
  print('🚨 Service is in failure state');
}

// Check queue size
if (googleSheetsService.failedUploads.length > 10) {
  print('⚠️ Large backlog of failed uploads');
}
```

---

## Summary

The error handling system ensures:

✅ **No data loss** - Failed uploads queued for retry  
✅ **Automatic recovery** - Retries with exponential backoff  
✅ **Resource protection** - Circuit breaker prevents battery drain  
✅ **Partial success** - Metadata logged even if media fails  
✅ **User feedback** - Error callbacks and logging  
✅ **Manual recovery** - Retry and clear functions  
✅ **Graceful degradation** - Works even with partial failures  

**Result:** The system is resilient and reliable, handling real-world network issues gracefully without losing detection events.
