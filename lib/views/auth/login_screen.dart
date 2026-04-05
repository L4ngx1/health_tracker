import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/route_transitions.dart';
import '../widgets/common_widgets.dart';
import '../widgets/auth_layout.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _controller = AuthController();
  bool _isLoading = false;
  String? _errorMessage;

  bool _isCancelLikeMessage(String message) {
    final text = message.toLowerCase();
    return text.contains('canceled') ||
        text.contains('cancelled') ||
        text.contains('hủy đăng nhập google');
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    _setLoading(true);
    final email = _userController.text.trim();
    final password = _passwordController.text;

    _setError(null);
    final error = await _controller.login(email: email, password: password);
    if (!mounted) return;

    _setLoading(false);
    if (error != null) {
      _setError(error);
      return;
    }

    _setError(null);
    navigator.pushReplacementNamed(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AuthLayout(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact centered header without back button (primary entry point)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandIconOnly(),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.appTitle(context),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.loginWelcomeBack(context),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.loginSubtitle(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 12, bottom: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        border: Border.all(color: colorScheme.error),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  InputLabel(AppStrings.emailLabel(context)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _userController,
                    hint: AppStrings.emailHint(context),
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.emailRequired(context);
                      }
                      if (!RegExp(
                        r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}",
                      ).hasMatch(value.trim())) {
                        return AppStrings.emailInvalid(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  InputLabel(AppStrings.passwordLabel(context)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _passwordController,
                    hint: AppStrings.passwordHint(context),
                    icon: Icons.lock_outline,
                    obscureText: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.passwordRequired(context);
                      }
                      if (value.length < 6) {
                        return AppStrings.passwordTooShort(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          slidePageRoute(
                            ForgotPasswordScreen(
                              prefillEmail: _userController.text.trim(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.forgotPassword(context),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: AppStrings.login(context),
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 18),
                  DividerWithText(text: AppStrings.orLabel(context)),
                  const SizedBox(height: 18),
                  SocialButton(
                    text: AppStrings.continueWithGoogle(context),
                    onPressed: () async {
                      if (_isLoading) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      setState(() => _isLoading = true);
                      final error = await _controller.continueWithGoogle();
                      if (!mounted) return;
                      setState(() => _isLoading = false);

                      if (error == AuthController.googleSignInCanceled) {
                        return;
                      }

                      if (error != null && _isCancelLikeMessage(error)) {
                        return;
                      }

                      if (error != null) {
                        messenger.showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }

                      if (!mounted) return;
                      navigator.pushReplacementNamed(AppRoutes.main);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              setState(() => _isLoading = true);
                              final error =
                                  await _controller.signInAnonymously();
                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (error != null) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(error)),
                                );
                                return;
                              }

                              if (!mounted) return;
                              navigator.pushReplacementNamed(AppRoutes.main);
                            },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                      child: Text(
                        AppStrings.anonymousLogin(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Text(AppStrings.noAccount(context)),
                          GestureDetector(
                            onTap: () => _controller.toRegister(context),
                            child: Text(
                              AppStrings.registerNow(context),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
