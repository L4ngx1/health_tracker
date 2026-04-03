import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'hydration_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HydrationNotificationService.instance.init();

  final title = message.notification?.title?.trim();
  final body = message.notification?.body?.trim();
  if (title != null && title.isNotEmpty && body != null && body.isNotEmpty) {
    await HydrationNotificationService.instance.showLocalNotification(
      title: title,
      body: body,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission();

    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title?.trim() ??
          message.data['title']?.toString().trim();
      final body = message.notification?.body?.trim() ??
          message.data['body']?.toString().trim();
      if (title == null || title.isEmpty || body == null || body.isEmpty) {
        return;
      }
      await HydrationNotificationService.instance.showLocalNotification(
        title: title,
        body: body,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Push opened app: ${message.messageId}');
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          'Push launched app from terminated state: ${initialMessage.messageId}');
    }

    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('Push permission status: ${settings.authorizationStatus}');
  }
}
