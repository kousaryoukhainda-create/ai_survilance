# Google Sheets Auto-Upload Setup Guide

## Overview
This guide will help you set up **fully automatic** uploading of detection events to Google Sheets with images stored in Google Drive.

## What Gets Uploaded
- ✅ **Timestamp** - Date and time of detection
- ✅ **Description** - What was detected (e.g., "Person detected", "John Doe detected")
- ✅ **Confidence** - Detection confidence percentage
- ✅ **Snapshot Image** - Automatically uploaded to Google Drive
- ✅ **Video Recording** - Optional (max 10MB per video)
- ✅ **Detection Type** - Person, object, animal, vehicle
- ✅ **Identity** - Name if face was recognized

## Setup Steps (10 minutes)

### Step 1: Create Google Sheet

1. Go to [Google Sheets](https://sheets.google.com)
2. Click **Blank** to create a new spreadsheet
3. Name it: `AI Surveillance Log`
4. Create the following headers in **Row 1**:

| Column | Header |
|--------|--------|
| A | Timestamp |
| B | Date |
| C | Time |
| D | Description |
| E | Confidence (%) |
| F | Detected Type |
| G | Identity Name |
| H | Identity Confidence (%) |
| I | Person Count |
| J | Snapshot URL |
| K | Video URL |
| L | Notes |

### Step 2: Create Google Apps Script

1. In your Google Sheet, click **Extensions** → **Apps Script**
2. Delete any existing code
3. Copy and paste the script from **Step 3** below
4. Click **Save** (💾 icon)
5. Name it: `SurveillanceWebhook`

### Step 3: Copy This Apps Script Code

```javascript
/**
 * Google Apps Script for AI Surveillance Auto-Upload
 * 
 * This script receives webhook POST requests from the surveillance app
 * and logs detection events to Google Sheets with images in Google Drive.
 */

function doPost(e) {
  try {
    // Parse the incoming JSON data
    const data = JSON.parse(e.postData.contents);
    
    // Get the active spreadsheet
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    
    // Get or create the "Surveillance Images" folder in Google Drive
    const folder = getOrCreateDriveFolder();
    
    // Upload snapshot image if provided
    let snapshotUrl = '';
    if (data.snapshotBase64 && data.snapshotName) {
      snapshotUrl = uploadImageToDrive(data.snapshotBase64, data.snapshotName, folder);
    }
    
    // Upload video if provided
    let videoUrl = '';
    if (data.videoBase64 && data.videoName) {
      videoUrl = uploadImageToDrive(data.videoBase64, data.videoName, folder);
    }
    
    // Add row to spreadsheet
    sheet.appendRow([
      data.timestamp || '',
      data.date || '',
      data.time || '',
      data.description || '',
      data.confidence || '',
      data.detectedType || '',
      data.identityName || '',
      data.identityConfidence || '',
      data.personCount || '',
      snapshotUrl,
      videoUrl,
      data.videoNote || ''
    ]);
    
    // Sort by timestamp (newest first)
    sortSheetByTimestamp(sheet);
    
    // Return success response
    return ContentService.createTextOutput(JSON.stringify({
      status: 'success',
      message: 'Detection logged successfully'
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    // Log error and return error response
    Logger.log('Error: ' + error.toString());
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Upload base64 image to Google Drive and return shareable link
 */
function uploadImageToDrive(base64Data, fileName, folder) {
  try {
    // Decode base64 data
    const decodedBytes = Utilities.base64Decode(base64Data);
    const blob = Utilities.newBlob(decodedBytes, 'image/jpeg', fileName);
    
    // Create file in folder
    const file = folder.createFile(blob);
    
    // Set sharing permissions (anyone with link can view)
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    
    // Return the file URL
    return file.getUrl();
    
  } catch (error) {
    Logger.log('Upload error: ' + error.toString());
    return 'Upload failed: ' + error.toString();
  }
}

/**
 * Get or create the "Surveillance Images" folder in Google Drive
 */
function getOrCreateDriveFolder() {
  const folderName = 'AI Surveillance Images';
  
  // Search for existing folder
  const folders = DriveApp.getFoldersByName(folderName);
  if (folders.hasNext()) {
    return folders.next();
  }
  
  // Create new folder
  const folder = DriveApp.createFolder(folderName);
  folder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  return folder;
}

/**
 * Sort sheet by timestamp (column A, newest first)
 */
function sortSheetByTimestamp(sheet) {
  const lastRow = sheet.getLastRow();
  if (lastRow > 2) { // Only sort if there's data beyond headers
    const range = sheet.getRange(2, 1, lastRow - 1, sheet.getLastColumn());
    range.sort({column: 1, ascending: false});
  }
}

/**
 * Test function - run this to verify the script works
 */
function testWebhook() {
  const testData = {
    timestamp: new Date().toISOString(),
    date: '11/04/2026',
    time: '14:30',
    description: 'Test - Person detected',
    confidence: '85.5',
    detectedType: 'person',
    identityName: 'Test User',
    identityConfidence: '90.0',
    personCount: '1'
  };
  
  const mockEvent = {
    postData: {
      contents: JSON.stringify(testData)
    }
  };
  
  const response = doPost(mockEvent);
  Logger.log(response.getContent());
}
```

### Step 4: Deploy as Web App

1. Click **Deploy** → **New deployment** (blue button in top right)
2. Click the **gear icon** ⚙️ next to "Select type"
3. Choose **Web app**
4. Fill in the details:
   - **Description**: `AI Surveillance Webhook`
   - **Execute as**: `Me (your email)`
   - **Who has access**: `Anyone` ⚠️ **IMPORTANT: Must be "Anyone"**
5. Click **Deploy**
6. **Authorize the script** when prompted:
   - Click **Review permissions**
   - Select your Google account
   - Click **Advanced** → **Go to SurveillanceWebhook (unsafe)**
   - Click **Allow**
7. Copy the **Web app URL** - this is your webhook URL!

The URL looks like:
```
https://script.google.com/macros/s/AKfycbxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/exec
```

### Step 5: Configure in App

1. Open your AI Surveillance app
2. Go to **Settings** → **Google Sheets Auto-Log**
3. Toggle **Auto-Upload to Google Sheets** to enable
4. Tap **Webhook URL**
5. Paste the URL from Step 4
6. Tap **Save**
7. Tap **Test Connection** to verify it works

### Step 6: Test It!

1. Start monitoring in the app
2. Trigger a detection (walk in front of camera)
3. Check your Google Sheet - a new row should appear automatically!
4. Check Google Drive → "AI Surveillance Images" folder for uploaded images

## How It Works

```
Detection Event
    ↓
App captures snapshot
    ↓
App converts image to base64
    ↓
App sends POST to webhook URL
    ↓
Google Apps Script receives data
    ↓
Script uploads image to Google Drive
    ↓
Script adds row to Google Sheet with image URL
    ↓
Sheet sorts automatically (newest first)
```

## Features

### ✅ Fully Automatic
- No user interaction needed
- Runs in background
- Works even when app is closed (after detection)

### ✅ Image Upload
- Snapshots uploaded to Google Drive
- Stored in "AI Surveillance Images" folder
- Shareable links added to spreadsheet
- Anyone with link can view (read-only)

### ✅ Video Upload (Optional)
- Videos under 10MB uploaded automatically
- Larger videos logged with note
- Toggle on/off in settings

### ✅ Organized Data
- All detections logged chronologically
- Sorted by newest first
- Includes all metadata (confidence, identity, etc.)

## Troubleshooting

### "Webhook test failed"
- Verify the URL is correct and complete
- Ensure deployment is set to "Anyone has access"
- Try redeploying the script (create new version)

### Images not uploading
- Check "Upload Snapshots" is enabled in app settings
- Verify snapshot file exists in app
- Check Google Drive storage quota

### "Script not authorized"
- Re-authorize the script in Google Apps Script
- Check Drive and Sheets permissions are granted

### Data appears but no images
- Images may be too large (try reducing camera resolution)
- Check base64 encoding is working
- Verify Google Drive quota

## Advanced Customization

### Change Image Format
In the Apps Script, modify the blob creation:
```javascript
// Change from JPEG to PNG
const blob = Utilities.newBlob(decodedBytes, 'image/png', fileName);
```

### Add Email Notifications
Add this to the `doPost` function:
```javascript
// Send email alert
MailApp.sendEmail({
  to: 'your-email@gmail.com',
  subject: '🚨 Detection Alert: ' + data.description,
  htmlBody: '<h2>Detection Details</h2>' +
            '<p><strong>Time:</strong> ' + data.time + '</p>' +
            '<p><strong>Description:</strong> ' + data.description + '</p>' +
            '<p><strong>Confidence:</strong> ' + data.confidence + '%</p>' +
            '<p><strong>Image:</strong> <a href="' + snapshotUrl + '">View Image</a></p>'
});
```

### Create Dashboard
Use Google Data Studio to create a visual dashboard:
1. Go to [datastudio.google.com](https://datastudio.google.com)
2. Connect to your Google Sheet
3. Create charts for:
   - Detections per day
   - Most common detection types
   - Confidence trends
   - Timeline view

## Privacy & Security

- 🔒 Webhook URL is unique to your deployment
- 🔒 Images stored in your Google Drive only
- 🔒 Only you can access the spreadsheet (unless shared)
- 🔒 Images shared with "anyone with link" (read-only)
- ⚠️ Don't share your webhook URL publicly
- ⚠️ Revoke access if URL is compromised (redeploy script)

## Costs

- ✅ **Google Sheets**: Free (up to 10 million cells)
- ✅ **Google Drive**: 15GB free (shared with Gmail)
- ✅ **Google Apps Script**: Free (6 min/day execution time limit)
- ✅ **No third-party services required**

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all setup steps are completed
3. Check Google Apps Script execution logs (View → Executions)
4. Test with the `testWebhook` function in Apps Script

---

**You're all set!** 🎉

Your AI surveillance app will now automatically log all detections to Google Sheets with images - fully automatically!
