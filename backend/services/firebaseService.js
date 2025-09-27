const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
function initializeFirebase() {
    if (admin.apps.length === 0) {
        // You'll need to add your Firebase service account key file
        // Download it from Firebase Console -> Project Settings -> Service Accounts
        try {
            const serviceAccount = require('../config/firebase-service-account.json');
            
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
            
            console.log('Firebase Admin initialized successfully');
        } catch (error) {
            console.error('Firebase Admin initialization failed:', error.message);
            console.log('Please add your Firebase service account key to backend/config/firebase-service-account.json');
        }
    }
}

// Send push notification to a specific user
async function sendNotificationToUser(fcmToken, notification, data = {}) {
    try {
        if (!admin.apps.length) {
            throw new Error('Firebase not initialized');
        }

        const message = {
            token: fcmToken,
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: {
                ...data,
                // Ensure all data values are strings
                timestamp: new Date().toISOString(),
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        const response = await admin.messaging().send(message);
        console.log('Push notification sent successfully:', response);
        return response;
    } catch (error) {
        console.error('Error sending push notification:', error);
        throw error;
    }
}

// Send message notification
async function sendMessageNotification(recipientFcmToken, senderName, messageContent, listingTitle, conversationData = {}) {
    const notification = {
        title: `New message from ${senderName}`,
        body: messageContent || 'Sent an image',
    };

    const data = {
        type: 'message',
        senderId: String(conversationData.senderId || ''),
        listingId: String(conversationData.listingId || ''),
        listingTitle: listingTitle || '',
        senderName: senderName || '',
    };

    return await sendNotificationToUser(recipientFcmToken, notification, data);
}

module.exports = {
    initializeFirebase,
    sendNotificationToUser,
    sendMessageNotification,
};

