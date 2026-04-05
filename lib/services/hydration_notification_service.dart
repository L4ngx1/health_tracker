import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'permission_queue.dart';

class HydrationNotificationService {
  HydrationNotificationService._();

  static final HydrationNotificationService instance =
      HydrationNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const String _prefNotificationsEnabled = 'notifications_enabled';

  static const String generalChannelId = 'general_notifications';
  static const String generalChannelName = 'General notifications';
  static const String generalChannelDescription =
      'General app notifications from server';

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        generalChannelId,
        generalChannelName,
        description: generalChannelDescription,
        importance: Importance.max,
      ),
    );

    _initialized = true;
  }

  Future<void> requestPermissionIfNeeded() async {
    await PermissionQueue.instance.enqueue(() async {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await macos?.requestPermissions(alert: true, badge: true, sound: true);
    });
  }

  Future<void> showHydrationReminder({
    required String title,
    required String body,
  }) async {
    await showLocalNotification(
        title: title,
        body: body,
        channelId: 'hydration_reminders',
        channelName: 'Hydration reminders',
        channelDescription: 'Water intake reminders');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = generalChannelId,
    String channelName = generalChannelName,
    String channelDescription = generalChannelDescription,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefNotificationsEnabled) ?? true;
    if (!enabled) {
      return;
    }

    if (!_initialized) {
      await init();
    }

    await requestPermissionIfNeeded();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
