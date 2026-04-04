import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/auth_layout.dart';
import '../widgets/common_widgets.dart';

class UnverifiedScreen extends StatefulWidget {
  const UnverifiedScreen({super.key});

  @override
  State<UnverifiedScreen> createState() => _UnverifiedScreenState();
}

class _UnverifiedScreenState extends State<UnverifiedScreen> {
  final _controller = const AuthController();
  bool _loading = false;

  Future<void> _resend() async {
    setState(() => _loading = true);
    final error = await _controller.resendEmailVerification();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? AppStrings.resendVerification(context)),
      ),
    );
  }

  Future<void> _checkVerified() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (!mounted) return;
    setState(() => _loading = false);
    if (verified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.emailVerifiedSuccess(context))));
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.emailNotVerifiedYet(context))),
    );
  }

  Future<void> _signOut() async {
    await _controller.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AuthLayout(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandIconOnly(),
                const SizedBox(height: 12),
                Text(
                  AppStrings.appTitle(context),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.unverifiedTitle(context),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.unverifiedInstruction(context),
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.sentToEmail(context, email),
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  text: AppStrings.resendVerification(context),
                  isLoading: _loading,
                  onPressed: _resend,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _checkVerified,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                    child: Text(AppStrings.verifiedCheckAgain(context)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _signOut, child: Text(AppStrings.logout(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
