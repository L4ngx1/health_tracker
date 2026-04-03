import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/localization/locale_service.dart';
import 'core/theme/theme_service.dart';
import 'controllers/tracking_controller.dart';
import 'firebase_options.dart';
import 'services/hydration_notification_service.dart';

bool get _supportsWorkmanagerOnCurrentPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/.env', isOptional: true);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeService.instance.init();
  await LocaleService.instance.init();
  await HydrationNotificationService.instance.init();
  await HydrationNotificationService.instance.requestPermissionIfNeeded();
  if (_supportsWorkmanagerOnCurrentPlatform) {
    await Workmanager().initialize(trackingCallbackDispatcher);
  }
  runApp(const HealthTrackerApp());
}

//
