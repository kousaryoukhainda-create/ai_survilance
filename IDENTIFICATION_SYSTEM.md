# Person & Object Identification System

## Overview

The Movement Detector app now includes **AI-powered identification** to identify WHO and WHAT is detected, not just that movement occurred.

---

## 🎯 What It Does

### **Before (Motion Detection Only):**
```
Movement Detected → Save Snapshot → Notify
Notification: "Movement detected (85% confidence)"
```

### **After (With Identification):**
```
Movement Detected → AI Analysis → Identify → Save → Notify
Notification: "👤 John Doe detected (92% match)"
         OR: "🧑 Person detected"
         OR: "🚗 Vehicle detected"
         OR: "🐾 Animal detected"
```

---

## 🔧 How It Works

### **Complete Identification Pipeline**

```
┌─────────────────────────────────────────────────────────┐
│              Identification Flow                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Motion Detection (Current System)                   │
│     └─ Frame comparison detects movement                │
│     └─ If motion > 30% threshold → Continue             │
│                                                         │
│  2. Capture Snapshot                                    │
│     └─ Save high-quality image                          │
│     └─ Prepare for AI analysis                          │
│                                                         │
│  3. Object Detection (ML Kit)                           │
│     └─ Analyze image with AI model                      │
│     └─ Detect objects: Person, Car, Dog, etc.           │
│     └─ Count number of people                           │
│     └─ Get confidence scores                            │
│                                                         │
│  4. Face Detection (ML Kit)                             │
│     └─ If person detected → Look for faces              │
│     └─ Find face boundaries                             │
│     └─ Extract face features                            │
│                                                         │
│  5. Face Recognition (Custom Algorithm)                 │
│     └─ Compare with known persons database              │
│     └─ Calculate similarity score                       │
│     └─ If match > 60% → Identify person                 │
│                                                         │
│  6. Build Event                                         │
│     └─ Combine all identification data                  │
│     └─ Create rich movement event                       │
│                                                         │
│  7. Smart Notification                                  │
│     └─ Known person: "John Doe detected (92%)"          │
│     └─ Unknown person: "Person detected"                │
│     └─ Object: "Vehicle detected"                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Identification Results

### **Scenario 1: Known Person Detected**
```
┌─────────────────────────────────┐
│  [Camera with face match]       │
│                                 │
│     ┌─────────────────┐         │
│     │  John Doe       │         │
│     │  Match: 92%     │         │
│     └─────────────────┘         │
│                                 │
│  Event Details:                 │
│  ├─ Type: PERSON                │
│  ├─ Identity: John Doe          │
│  ├─ Confidence: 92%             │
│  ├─ Face Match: Yes             │
│  └─ Persons in frame: 1         │
│                                 │
│  Notification:                  │
│  👤 John Doe detected (92.0%)   │
└─────────────────────────────────┘
```

### **Scenario 2: Unknown Person**
```
┌─────────────────────────────────┐
│  [Camera with person box]       │
│                                 │
│     ┌─────────────┐             │
│     │   PERSON    │             │
│     │    95%      │             │
│     └─────────────┘             │
│                                 │
│  Event Details:                 │
│  ├─ Type: PERSON                │
│  ├─ Identity: Unknown           │
│  ├─ Face Detected: Yes          │
│  ├─ In Database: No             │
│  └─ Persons in frame: 1         │
│                                 │
│  Notification:                  │
│  🧑 Person detected             │
└─────────────────────────────────┘
```

### **Scenario 3: Multiple People**
```
┌─────────────────────────────────┐
│  [Camera with 2 person boxes]   │
│                                 │
│     ┌────┐      ┌────┐          │
│     │ P1 │      │ P2 │          │
│     └────┘      └────┘          │
│                                 │
│  Event Details:                 │
│  ├─ Type: PERSON                │
│  ├─ Persons in frame: 2         │
│  └─ Face Matches: 0             │
│                                 │
│  Notification:                  │
│  🧑 2 persons detected          │
└─────────────────────────────────┘
```

### **Scenario 4: Vehicle Detected**
```
┌─────────────────────────────────┐
│  [Camera with car detected]     │
│                                 │
│     ┌─────────────┐             │
│     │    CAR      │             │
│     │    87%      │             │
│     └─────────────┘             │
│                                 │
│  Event Details:                 │
│  ├─ Type: VEHICLE               │
│  ├─ Objects: Car (87%)          │
│  └─ Persons in frame: 0         │
│                                 │
│  Notification:                  │
│  🚗 Vehicle detected            │
└─────────────────────────────────┘
```

### **Scenario 5: Animal Detected**
```
┌─────────────────────────────────┐
│  [Camera with dog detected]     │
│                                 │
│     ┌─────────────┐             │
│     │    DOG      │             │
│     │    91%      │             │
│     └─────────────┘             │
│                                 │
│  Event Details:                 │
│  ├─ Type: ANIMAL                │
│  ├─ Objects: Dog (91%)          │
│  └─ Persons in frame: 0         │
│                                 │
│  Notification:                  │
│  🐾 Animal detected             │
└─────────────────────────────────┘
```

---

## 🗄️ Known Persons Database

### **Database Schema**

```sql
CREATE TABLE known_persons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,              -- Person's name
  faceEncoding TEXT NOT NULL,      -- Face feature vector (JSON)
  photoPath TEXT NOT NULL,         -- Path to reference photo
  createdAt TEXT NOT NULL,         -- When registered
  lastSeen TEXT,                   -- Last detection time
  detectionCount INTEGER DEFAULT 0,-- Total times detected
  notes TEXT                       -- Optional notes
)
```

### **Registering a New Person**

```
┌─────────────────────────────────┐
│  Register New Person            │
├─────────────────────────────────┤
│                                 │
│  Step 1: Select Photo           │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │    [Photo Preview]        │  │
│  │    with face box          │  │
│  │                           │  │
│  └───────────────────────────┘  │
│  [Take Photo] [Choose Gallery]  │
│                                 │
│  Step 2: Enter Name             │
│  ┌───────────────────────────┐  │
│  │ Person Name: John Doe     │  │
│  └───────────────────────────┘  │
│                                 │
│  Step 3: Add Notes (Optional)   │
│  ┌───────────────────────────┐  │
│  │ Notes: Family member      │  │
│  └───────────────────────────┘  │
│                                 │
│  [Register Person]              │
│                                 │
│  💡 Tips:                       │
│  • Use clear, well-lit photo    │
│  • Face should be visible       │
│  • Avoid sunglasses/hats        │
└─────────────────────────────────┘
```

### **Managing Known Persons**

```
┌─────────────────────────────────┐
│  Known Persons           [ + ]  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ [Photo] John Doe            │ │
│ │         Registered: Jan 15  │ │
│ │         Last seen: Today    │ │
│ │         Notes: Family       │ │
│ │                  15 detections│ │
│ │                     [Delete] │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [Photo] Jane Smith          │ │
│ │         Registered: Feb 20  │ │
│ │         Last seen: Yesterday│ │
│ │                  8 detections│ │
│ │                     [Delete] │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## ⚙️ Settings & Configuration

### **Identification Settings**

Access via: Settings → Person Identification section

| Setting | Default | Description |
|---------|---------|-------------|
| **Person Detection** | ✅ ON | Detect if movement is a person |
| **Face Recognition** | ✅ ON | Try to identify known persons |
| **Object Classification** | ✅ ON | Classify objects (car, pet, etc.) |
| **Face Match Threshold** | 60% | Minimum confidence to consider a match |

### **Adjusting Face Match Threshold**

```
Lower (40-50%): More matches, but more false positives
Default (60%): Balanced accuracy
Higher (70-80%): Fewer matches, but more accurate
```

---

## 🔍 Technical Details

### **Object Detection Classes**

ML Kit can detect these object categories:

| Category | Examples | Use Case |
|----------|----------|----------|
| **Person** | Human, People | Security monitoring |
| **Vehicle** | Car, Truck, Bus | Driveway monitoring |
| **Animal** | Dog, Cat, Bird | Pet detection |
| **Object** | Bag, Phone, etc. | General objects |

### **Face Detection Features**

Extracted face features for recognition:

```dart
Face Features Vector:
├─ Bounding box (width, height)
├─ Head rotation (X, Y, Z angles)
├─ Smiling probability (0-1)
├─ Left eye open probability (0-1)
├─ Right eye open probability (0-1)
└─ Face contours (landmarks)
```

### **Face Matching Algorithm**

```dart
1. Extract features from detected face
2. Load all known face encodings from database
3. For each known face:
   └─ Calculate cosine similarity
4. Find best match
5. If similarity >= threshold:
   └─ Return matched person
   └─ Update last seen timestamp
6. Else:
   └─ Return "Unknown person"
```

---

## 📱 User Workflows

### **Workflow 1: Register Family Member**

```
1. Open app → Settings → Known Persons
2. Tap "+ Add Person"
3. Enter name: "John Doe"
4. Tap "Take Photo" or "Choose from Gallery"
5. Select clear photo of John's face
6. Wait for face detection (green box appears)
7. Add notes: "Family member"
8. Tap "Register Person"
9. ✅ John Doe is now in database

Next time John appears:
→ App detects movement
→ AI identifies "Person"
→ Face recognition matches "John Doe (92%)"
→ Notification: "👤 John Doe detected (92.0%)"
→ Event saved with identity
```

### **Workflow 2: Unknown Person Alert**

```
1. Monitoring is active
2. Unknown person enters frame
3. Motion detection triggers
4. AI detects "Person" (95% confidence)
5. Face detection finds face
6. Face recognition: NO MATCH (not in database)
7. Event saved as "Unknown person"
8. Notification: "🧑 Person detected"
9. User can later register this person from snapshot
```

### **Workflow 3: Vehicle Detection**

```
1. Monitoring is active
2. Car pulls into driveway
3. Motion detection triggers
4. AI detects "Car" (87% confidence)
5. No faces detected
6. Event type: "VEHICLE"
7. Notification: "🚗 Vehicle detected"
```

---

## 🎨 UI Components

### **Movement Event with Identification**

```
┌─────────────────────────────────┐
│  Movement Event Details         │
├─────────────────────────────────┤
│                                 │
│  [Snapshot Image]               │
│  with bounding boxes            │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🧑 Type: Person           │  │
│  │ 👤 Identity: John Doe     │  │
│  │ 📊 Match: 92.3%           │  │
│  │ ████████████████░░        │  │
│  └───────────────────────────┘  │
│                                 │
│  📅 Timestamp:                  │
│  April 9, 2026 14:32:05         │
│                                 │
│  👥 Persons in frame: 1         │
│  📦 Objects: Person (95%)       │
│                                 │
│  [Share] [View Full]            │
└─────────────────────────────────┘
```

### **History List with Identification**

```
┌─────────────────────────────────┐
│  Movement History               │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ [IMG] 👤 John Doe detected  │ │
│ │       92.0% match           │ │
│ │       Apr 09, 2026 14:32    │ │
│ │       ████████████░░ 92%    │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [IMG] 🧑 Person detected    │ │
│ │       Unknown person        │ │
│ │       Apr 09, 2026 13:15    │ │
│ │       ████████░░░░ 67%      │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [IMG] 🚗 Vehicle detected   │ │
│ │       Apr 09, 2026 12:00    │ │
│ │       ██████████░░ 85%      │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## 🔐 Privacy & Security

### **Data Storage**
- ✅ All face data stored **locally only**
- ✅ No cloud transmission
- ✅ Face encodings are mathematical vectors (not photos)
- ✅ Photos stored in app's private directory

### **What's Stored**
```
Database stores:
├─ Face encoding (JSON array of numbers)
│  Example: [0.123, -0.456, 0.789, ...]
│  NOT the actual face photo
│
└─ Reference photo path
   Used for visual identification
   Stored in app's private folder
```

### **Deleting Data**
```
Delete Person → Removes from database
              → Deletes reference photo
              → Face encoding permanently removed
```

---

## ⚡ Performance

### **Processing Time per Detection**

| Step | Time | Can Skip? |
|------|------|-----------|
| Motion Detection | 50ms | No (trigger) |
| Object Detection | 200ms | Yes (if disabled) |
| Face Detection | 150ms | Yes (if disabled) |
| Face Recognition | 50ms | Yes (if no faces) |
| **Total** | **450ms** | **~250ms if disabled** |

### **Optimization Strategies**

```dart
// Only run identification when motion detected
if (motionScore > threshold) {
  // Run AI analysis
  if (enableIdentification) {
    result = await identifyFrame();
  }
}

// Cache results for 5 seconds
// Avoid re-processing same person
if (lastAnalysisTime < 5.seconds.ago) {
  return cachedResult;
}

// Skip face recognition if no person detected
if (detectedType != 'person') {
  skip faceRecognition;
}
```

---

## 🐛 Troubleshooting

### **Face Not Detected**

**Problem:** "No face detected in image"

**Solutions:**
1. Use better lighting
2. Ensure face is clearly visible
3. Face should be front-facing
4. Remove sunglasses
5. Try a different photo

### **Wrong Person Matched**

**Problem:** App identifies wrong person

**Solutions:**
1. Increase face match threshold (Settings)
2. Re-register person with better photo
3. Add multiple photos of same person (future feature)
4. Check lighting conditions

### **Slow Performance**

**Problem:** Identification takes too long

**Solutions:**
1. Disable face recognition if not needed
2. Disable object classification
3. Use lower camera resolution
4. Increase motion threshold (fewer triggers)

### **No Objects Detected**

**Problem:** Only shows "Unknown" type

**Solutions:**
1. Check ML Kit is initialized
2. Ensure object detection is enabled
3. Check internet (some models need download)
4. Try with clearer image

---

## 🚀 Future Enhancements

### **Planned Features**

- [ ] Multi-face registration (multiple photos per person)
- [ ] Activity recognition (walking, running, sitting)
- [ ] Pose estimation (body position)
- [ ] Emotion detection (happy, sad, angry)
- [ ] Age estimation
- [ ] Gender detection
- [ ] Person re-identification (track across frames)
- [ ] Heat map of person locations
- [ ] Timeline view of person movements
- [ ] Export identification history
- [ ] Statistics dashboard
- [ ] Custom object training

---

## 📚 API Reference

### **IdentificationService**

```dart
// Initialize
await IdentificationService.instance.initialize();

// Analyze frame
final result = await IdentificationService.instance.analyzeFrame(inputImage);

// Register person
await IdentificationService.instance.registerPerson(
  name: 'John Doe',
  photoPath: '/path/to/photo.jpg',
  face: detectedFace,
  notes: 'Family member',
);

// Get known persons
final persons = await IdentificationService.instance.getKnownPersons();

// Delete person
await IdentificationService.instance.deleteKnownPerson(id);

// Update settings
IdentificationService.instance.updateSettings(
  enablePersonDetection: true,
  enableFaceRecognition: true,
  enableObjectClassification: true,
  faceMatchThreshold: 0.6,
);
```

### **IdentificationResult**

```dart
class IdentificationResult {
  String detectedType;          // 'person', 'object', 'animal', 'vehicle'
  int personCount;              // Number of people detected
  List<DetectedObject> objects; // ML Kit detected objects
  List<Face> faces;            // Detected faces
  String? identityName;        // Matched person's name
  double? identityConfidence;  // Match confidence (0-1)
  bool isFaceMatched;          // Whether face matched database
}
```

---

## 📊 Statistics & Analytics

### **Track Detection Patterns**

```
Known Persons Screen shows:
├─ Total detections per person
├─ Last seen timestamp
├─ Registration date
└─ Detection frequency

Example:
John Doe: 15 detections
├─ First: Jan 15, 2026
├─ Last: Today at 14:32
├─ Average: 2 per day
└─ Most active: Mornings (8-10 AM)
```

---

This identification system transforms your movement detector into a **smart surveillance system** that knows WHO is there, not just THAT someone is there!
