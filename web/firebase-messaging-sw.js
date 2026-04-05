/*
  Firebase Messaging service worker for Flutter web.
  Keep this file at web/firebase-messaging-sw.js so the browser can register it
  under '/firebase-cloud-messaging-push-scope'.
*/

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA5ZZuPc8Xijwno9fKyUynmVKpvdQnTVUg',
  authDomain: 'health-tracker-84761.firebaseapp.com',
  projectId: 'health-tracker-84761',
  storageBucket: 'health-tracker-84761.firebasestorage.app',
  messagingSenderId: '607294559860',
  appId: '1:607294559860:web:4df798fafcaf69bc4f0eb5',
  measurementId: 'G-B3J3VB6W3D',
});

firebase.messaging();
