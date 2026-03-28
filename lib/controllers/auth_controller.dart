import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';

class AuthController {
  const AuthController();

  void toRegister(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  void toLogin(BuildContext context) {
    Navigator.of(context).pop();
  }

  void login(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
  }

  void signup(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
  }

  void continueWithGoogle(BuildContext context, {required bool clearStack}) {
    if (clearStack) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
  }
}
