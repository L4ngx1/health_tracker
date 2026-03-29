import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'controllers/tracking_controller.dart';

bool get _supportsWorkmanagerOnCurrentPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supportsWorkmanagerOnCurrentPlatform) {
    await Workmanager().initialize(trackingCallbackDispatcher);
  }
  runApp(const HealthTrackerApp());
}
