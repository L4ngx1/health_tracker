import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/localization/app_strings.dart';
import 'core/localization/locale_service.dart';
import 'l10n/app_localizations.dart';
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
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleService.instance.locale,
          builder: (context, locale, _) {
            return ScreenUtilInit(
              designSize:
                  const Size(375, 812), // Ví dụ thiết kế theo iPhone 11/12
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (context, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  onGenerateTitle: (context) => AppStrings.appTitle(context),
                  scrollBehavior: const AppScrollBehavior(),
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeMode,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  home:
                      child, // Khởi tạo AuthGate dưới dạng child của ScreenUtilInit
                  onGenerateRoute: AppRoutes.onGenerateRoute,
                  // Fallback routes for safety
                  routes: AppRoutes.routes,
                );
              },
              child: const _AuthGate(),
            );
          },
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
