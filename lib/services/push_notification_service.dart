import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'backend_api_service.dart';
import 'hydration_notification_service.dart';
import 'permission_queue.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final enabled = await PushNotificationService.areNotificationsEnabled();
  if (!enabled) {
    return;
  }

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
  static const String notificationsEnabledKey = 'notifications_enabled';

  final BackendApiService _backendApiService = BackendApiService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, enabled);

    if (!enabled) {
      await _clearBackendTokenForCurrentUser();
      if (!kIsWeb) {
        try {
          await _messaging.deleteToken();
        } catch (e) {
          debugPrint('Delete FCM token failed: $e');
        }
      }
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      _initialized = false;
      return;
    }

    await init();
    final settings = await _requestPermission();
    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!allowed) {
      return;
    }
    await syncTokenForCurrentUser();
  }

  Future<void> init({bool requestPermission = false}) async {
    if (kIsWeb) return;

    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      return;
    }

    if (_initialized) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (requestPermission) {
      final settings = await _requestPermission();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        _initialized = true;
        return;
      }
    }

    await syncTokenForCurrentUser();

    FirebaseMessaging.onMessage.listen((message) async {
      final canShow = await areNotificationsEnabled();
      if (!canShow) {
        return;
      }

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

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final enabled = await areNotificationsEnabled();
      if (!enabled || token.trim().isEmpty) {
        return;
      }
      await _saveTokenToBackend(token);
    });

    _initialized = true;
  }

  Future<NotificationSettings> _requestPermission() async {
    final settings = await PermissionQueue.instance.enqueue(
      () => _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      ),
    );
    debugPrint('Push permission status: ${settings.authorizationStatus}');
    return settings;
  }

  Future<void> syncTokenForCurrentUser() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    String? token;
    try {
      token = await _messaging.getToken();
    } on FirebaseException catch (e) {
      // On web, blocked notification permission is expected and should not
      // break auth or other user flows.
      if (e.code == 'permission-blocked' || e.code == 'permission-default') {
        debugPrint('Skip FCM token sync: ${e.code}.');
        return;
      }
      debugPrint('Get FCM token failed: ${e.code} - ${e.message ?? ''}');
      return;
    } catch (e) {
      debugPrint('Get FCM token failed: $e');
      return;
    }

    if (token == null || token.trim().isEmpty) {
      return;
    }
    await _saveTokenToBackend(token);
  }

  Future<void> handleUserLogout() async {
    await _clearBackendTokenForCurrentUser();
    if (!kIsWeb) {
      try {
        await _messaging.deleteToken();
      } catch (e) {
        debugPrint('Delete FCM token on logout failed: $e');
      }
    }
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _initialized = false;
  }

  Future<AuthorizationStatus> getAuthorizationStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _backendApiService.saveMyFcmToken(token);
      debugPrint('Saved FCM token to backend.');
    } catch (e) {
      debugPrint('Save FCM token failed: $e');
    }
  }

  Future<void> _clearBackendTokenForCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      await _backendApiService.clearMyFcmToken();
      debugPrint('Cleared FCM token on backend.');
    } catch (e) {
      debugPrint('Clear backend FCM token failed: $e');
    }
  }
}
