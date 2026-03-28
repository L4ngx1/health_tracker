import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';

class HealthTrackerApp extends StatefulWidget {
  const HealthTrackerApp({super.key});

  @override
  State<HealthTrackerApp> createState() => _HealthTrackerAppState();
}

class _HealthTrackerAppState extends State<HealthTrackerApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sống Khỏe',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          // Fallback routes for safety
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
