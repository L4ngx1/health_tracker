import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/unverified_screen.dart';
import 'views/main/main_navigation_screen.dart';

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
          scrollBehavior: const AppScrollBehavior(),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const _AuthGate(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          // Fallback routes for safety
          routes: AppRoutes.routes,
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        final bool mustVerifyEmail =
            !user.isAnonymous && user.email != null && !user.emailVerified;
        if (mustVerifyEmail) {
          return const UnverifiedScreen();
        }

        return const MainNavigationScreen();
      },
    );
  }
}
