importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCAazMj-_vstlN7iyltTKCA2v9MZsqWTSA",
  authDomain: "flow-chat-5e38b.firebaseapp.com",
  projectId: "flow-chat-5e38b",
  messagingSenderId: "156617951416",
  appId: "1:156617951416:web:5e8e6901299a7e19730c4d"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'Flow';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click — open app and navigate to chat
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const chatId = event.notification.data?.chatId;
  const url = chatId ? `/?chatId=${chatId}` : '/';
  event.waitUntil(clients.openWindow(url));
});
