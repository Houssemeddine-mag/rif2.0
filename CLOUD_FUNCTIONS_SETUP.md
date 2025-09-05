# Firebase Cloud Functions for Push Notifications

This file contains the Cloud Function needed to send push notifications when admin creates notifications.

## Setup Instructions

1. Install Firebase CLI:

```bash
npm install -g firebase-tools
```

2. Login to Firebase:

```bash
firebase login
```

3. Initialize Cloud Functions in your project:

```bash
firebase init functions
```

4. Replace the content of `functions/index.js` with the code below:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Cloud Function to send push notifications
exports.sendPushNotification = functions.firestore
  .document("push_notifications/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (data.sent) {
      return null; // Already processed
    }

    const { title, body, tokens, data: notificationData } = data;

    if (!tokens || tokens.length === 0) {
      console.log("No tokens to send to");
      return null;
    }

    // Create the notification payload
    const payload = {
      notification: {
        title: title,
        body: body,
        icon: "https://www.univ-constantine2.dz/rif/25/assets/images/logo.png",
        sound: "default",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      data: notificationData || {},
    };

    try {
      // Send to multiple devices
      const response = await admin.messaging().sendToDevice(tokens, payload, {
        priority: "high",
        timeToLive: 60 * 60 * 24, // 24 hours
      });

      console.log("Successfully sent message:", response);

      // Mark as sent
      await snap.ref.update({ sent: true, response: response });

      return response;
    } catch (error) {
      console.error("Error sending message:", error);
      await snap.ref.update({ sent: false, error: error.message });
      throw error;
    }
  });

// Alternative: Send to topic instead of individual tokens
exports.sendTopicNotification = functions.firestore
  .document("topic_notifications/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (data.sent) {
      return null;
    }

    const { title, body, topic = "all_users", data: notificationData } = data;

    const payload = {
      notification: {
        title: title,
        body: body,
        icon: "https://www.univ-constantine2.dz/rif/25/assets/images/logo.png",
        sound: "default",
      },
      data: notificationData || {},
    };

    try {
      const response = await admin.messaging().sendToTopic(topic, payload);
      console.log("Successfully sent topic message:", response);

      await snap.ref.update({ sent: true, response: response });
      return response;
    } catch (error) {
      console.error("Error sending topic message:", error);
      await snap.ref.update({ sent: false, error: error.message });
      throw error;
    }
  });

// Clean up old tokens
exports.cleanupTokens = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // 30 days ago
    );

    const query = admin
      .firestore()
      .collection("fcm_tokens")
      .where("createdAt", "<", cutoff);

    const snapshot = await query.get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log("Cleaned up old tokens:", snapshot.size);
    return null;
  });
```

## Deploy the function:

```bash
firebase deploy --only functions
```

## Alternative: Using Topic-based notifications

If you prefer to use topics instead of individual tokens, update the push notification service to subscribe users to a topic:

In your Flutter app initialization:

```dart
await PushNotificationService.subscribeToTopic('all_users');
```

Then modify the notification service to send to topics instead of individual tokens.

## Testing

1. Send a test notification from the admin interface
2. Check the Firebase Console > Functions logs for any errors
3. Verify notifications appear on user devices even when app is closed

## Security Rules

Add these Firestore security rules:

```javascript
// Allow authenticated users to read notifications
match /notifications/{document} {
  allow read: if request.auth != null;
  allow write: if false; // Only admin can write via Cloud Functions
}

// Allow authenticated users to read/write their FCM tokens
match /fcm_tokens/{tokenId} {
  allow read, write: if request.auth != null;
}

// Only allow Cloud Functions to write push notification requests
match /push_notifications/{document} {
  allow read, write: if false; // Only Cloud Functions
}
```
