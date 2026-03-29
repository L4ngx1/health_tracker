import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:workmanager/workmanager.dart';
import 'core/theme/theme_service.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // Only initialize Workmanager on mobile platforms (Android/iOS).
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Workmanager().initialize(trackingCallbackDispatcher);
    }
  }

  await ThemeService.instance.init();
  runApp(const HealthTrackerApp());
}

void trackingCallbackDispatcher() {
  // TODO: Implement background task logic if needed
}
