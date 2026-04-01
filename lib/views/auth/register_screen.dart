import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _controller = AuthController();
  bool _isLoading = false;
  String? _errorMessage;

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
    _nameController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    _setError(null);
    _setLoading(true);

    final error = await _controller.signup(
      fullName: _nameController.text.trim(),
      email: _userController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    _setLoading(false);

    if (error != null) {
      _setError(error);
      return;
    }

    _setError(null);
    navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AuthLayout(
        showBack: true,
        onBack: () => _controller.toLogin(context),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header: centered brand + compact section header (back button provided by AuthLayout)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandIconOnly(),
                      SizedBox(height: 10),
                      Text(
                        AppStrings.appTitle(context),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppStrings.registerTitle(context),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppStrings.registerSubtitle(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
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
                  const SizedBox(height: 18),
                  InputLabel(AppStrings.fullNameLabel(context)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _nameController,
                    hint: AppStrings.fullNameHint(context),
                    icon: Icons.person_outline,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocus),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fullNameRequired(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InputLabel(AppStrings.emailLabel(context)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _userController,
                    hint: AppStrings.emailHint(context),
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 12),
                  InputLabel(AppStrings.passwordLabel(context)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _passwordController,
                    hint: AppStrings.passwordHint(context),
                    icon: Icons.lock_outline,
                    obscureText: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_confirmFocus),
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
                  const SizedBox(height: 12),
                  InputLabel(AppStrings.confirmPasswordLabel(context)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _confirmPasswordController,
                    hint: AppStrings.confirmPasswordHint(context),
                    icon: Icons.lock_outline,
                    obscureText: true,
                    focusNode: _confirmFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.confirmPasswordRequired(context);
                      }
                      if (value != _passwordController.text) {
                        return AppStrings.passwordMismatch(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: AppStrings.register(context),
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  DividerWithText(text: AppStrings.orLabel(context)),
                  const SizedBox(height: 14),
                  SocialButton(
                    text: AppStrings.continueWithGoogle(context),
                    onPressed: _isLoading
                        ? () {}
                        : () async {
                            final navigator = Navigator.of(context);

                            _setLoading(true);
                            final error = await _controller
                                .continueWithGoogle();
                            if (!mounted) return;
                            _setLoading(false);

                            if (error != null) {
                              _setError(error);
                              return;
                            }

                            if (!mounted) return;
                            _setError(null);
                            navigator.pushNamedAndRemoveUntil(
                              AppRoutes.main,
                              (route) => false,
                            );
                          },
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppStrings.haveAccount(context)),
                          GestureDetector(
                            onTap: () => _controller.toLogin(context),
                            child: Text(
                              AppStrings.loginNow(context),
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
