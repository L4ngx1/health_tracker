import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'controllers/tracking_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Workmanager().initialize(trackingCallbackDispatcher);
  }
  runApp(const HealthTrackerApp());
}
