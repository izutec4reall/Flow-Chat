const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// FCM: send notification when a new message is created
exports.onNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const { chatId } = context.params;
    const message = snap.data();
    if (!message) return;

    const senderId = message.senderId;
    const text = message.text || message.caption || '';

    // Get chat participants
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;
    const chat = chatDoc.data();
    const participants = chat?.participants || [];
    if (participants.length === 0) return;

    // Build notification for each participant except the sender
    const promises = participants
      .filter((uid) => uid !== senderId)
      .map(async (uid) => {
        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) return;
        const tokens = userDoc.data()?.fcmTokens || [];
        if (tokens.length === 0) return;

        // Get sender's name
        const senderDoc = await db.collection('users').doc(senderId).get();
        const senderName = senderDoc.data()?.displayName || 'Someone';

        const payload = {
          notification: {
            title: senderName,
            body: text || 'Sent a message',
          },
          data: {
            chatId,
            senderId,
          },
        };

        return admin.messaging().sendEachForMulticast({
          tokens,
          ...payload,
        }).catch(() => {});
      });

    await Promise.all(promises);
  });
