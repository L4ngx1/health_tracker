import 'package:flutter/material.dart';

import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/auth/unverified_screen.dart';
import '../../views/main/main_navigation_screen.dart';
import '../../views/main/profile_screen.dart';
import '../../views/main/settings_screen.dart';
import 'route_transitions.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String unverified = '/unverified';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (_) => const LoginScreen(),
      register: (_) => const RegisterScreen(),
      forgotPassword: (_) => const ForgotPasswordScreen(),
      unverified: (_) => const UnverifiedScreen(),
      main: (_) => const MainNavigationScreen(),
      profile: (_) => const ProfileScreen(),
      settings: (_) => const SettingsScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case '/':
      case login:
        return slidePageRoute(const LoginScreen());
      case register:
        return slidePageRoute(const RegisterScreen());
      case forgotPassword:
        return slidePageRoute(const ForgotPasswordScreen());
      case unverified:
        return slidePageRoute(const UnverifiedScreen());
      case main:
        return slidePageRoute(const MainNavigationScreen());
      case profile:
        return slidePageRoute(const ProfileScreen());
      case settings:
        return slidePageRoute(const SettingsScreen());
      default:
        // Fallback in case the route name is missing or requires restoration.
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
