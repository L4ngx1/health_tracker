import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateHomeWidget() async {
  final prefs = await SharedPreferences.getInstance();
  final steps = prefs.getInt('tracking.steps') ?? 0;
  final distance = prefs.getDouble('tracking.distanceMeters') ?? 0.0;
  await HomeWidget.saveWidgetData('steps', steps);
  await HomeWidget.saveWidgetData('distance', distance);
  await HomeWidget.updateWidget(
    name: 'HealthWidgetProvider',
    iOSName: 'HealthWidget',
  );
}
