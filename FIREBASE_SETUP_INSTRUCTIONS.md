# Firebase Push Notifications Setup Instructions

## Backend Setup ✅ (Completed)
- [x] Firebase Admin SDK installed
- [x] Database schema updated with FCM token field
- [x] Push notification service created
- [x] Message endpoint updated to send notifications
- [x] FCM token update endpoint added

## Required Manual Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or use existing project
3. Follow the setup wizard

### 2. Add iOS App to Firebase Project
1. In Firebase Console, click "Add app" → iOS
2. Enter iOS Bundle ID: `com.alexwang.UTD-marketplace` (check in Xcode for exact bundle ID)
3. Download `GoogleService-Info.plist`
4. **Important**: Add `GoogleService-Info.plist` to your Xcode project:
   - Drag it into Xcode project navigator
   - Make sure "Add to target" is checked
   - Place it in the root of your project

### 3. Add Firebase SDK to iOS Project
1. In Xcode, go to File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select "Up to Next Major Version"
4. Add these packages:
   - **FirebaseMessaging** (required)
   - **FirebaseAnalytics** (optional but recommended)

### 4. Configure Apple Push Notification Service (APNs)
1. In Apple Developer Portal:
   - Go to Certificates, Identifiers & Profiles
   - Select your App ID
   - Enable "Push Notifications" capability
   - Create APNs certificates (both Development and Production)

2. In Firebase Console:
   - Go to Project Settings → Cloud Messaging
   - Upload your APNs certificates
   - Or use APNs Auth Key (recommended)

### 5. Add Push Notification Capability in Xcode
1. Select your project in Xcode
2. Go to Signing & Capabilities tab
3. Click "+ Capability"
4. Add "Push Notifications"

### 6. Firebase Service Account (for Backend)
1. In Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Save it as: `backend/config/firebase-service-account.json`
5. **Important**: Add this file to `.gitignore` (contains secrets!)

## Testing the Setup

### 1. Start Backend Server
```bash
cd backend
npm start
```

### 2. Build and Run iOS App
1. Connect a physical iOS device (push notifications don't work in simulator)
2. Build and run the app on device
3. Allow notification permissions when prompted
4. Sign in to the app

### 3. Test Notifications
1. Open the app and navigate to a conversation
2. Use another device/browser to send a message to that conversation
3. You should receive a push notification

## Expected Behavior

- **When app is closed/background**: Push notification appears in notification center
- **When app is open**: Notification appears as banner at top
- **Tapping notification**: Opens the app and navigates to the conversation

## Common Issues & Solutions

### Firebase Not Initialized
- Error: `FirebaseApp.configure() not called`
- Solution: Ensure `GoogleService-Info.plist` is added to Xcode project

### No Push Notifications Received
1. Check device permissions: Settings → [Your App] → Notifications
2. Verify FCM token is being sent to backend (check server logs)
3. Ensure APNs certificates are properly configured in Firebase
4. Test on physical device (not simulator)

### Backend Errors
- `Firebase service account not found`: Add the JSON file to `backend/config/`
- `ENOENT: no such file`: Check the path to `firebase-service-account.json`

## Security Notes

- Never commit `firebase-service-account.json` to git
- FCM tokens are sensitive - only store them securely
- Use environment variables for production configuration

## Next Steps After Setup

1. Test end-to-end messaging with push notifications
2. Customize notification sounds and appearance
3. Add notification badges
4. Implement notification action buttons (reply, view, etc.)
5. Add analytics to track notification engagement

---

**Note**: This implementation sends notifications for all new messages. You may want to add settings later to let users control notification preferences.

