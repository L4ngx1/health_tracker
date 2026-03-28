import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/route_transitions.dart';
import '../../core/theme/app_palette.dart';
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
    return Scaffold(
      body: AuthLayout(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
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
                      children: const [
                        BrandIconOnly(),
                        SizedBox(height: 10),
                        Text(
                          'Sống Khỏe',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.textMain,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chào mừng trở lại',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF202936),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Đăng nhập để tiếp tục theo dõi và cải thiện sức khỏe của bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppPalette.textMuted,
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
                        color: const Color(0xFFFFF0F0),
                        border: Border.all(color: const Color(0xFFEB5757)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB41F1F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const InputLabel('Email'),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _userController,
                    hint: 'Nhập email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(
                        r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}",
                      ).hasMatch(value.trim())) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const InputLabel('Mật khẩu'),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _passwordController,
                    hint: 'Nhập mật khẩu',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải ít nhất 6 ký tự';
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
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: AppPalette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'Đăng nhập',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 18),
                  const DividerWithText(text: 'HOẶC'),
                  const SizedBox(height: 18),
                  SocialButton(
                    text: 'Tiếp tục với Google',
                    onPressed: () async {
                      if (_isLoading) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      setState(() => _isLoading = true);
                      final error = await _controller.continueWithGoogle();
                      if (!mounted) return;
                      setState(() => _isLoading = false);

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
                              final error = await _controller
                                  .signInAnonymously();
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
                        side: const BorderSide(color: AppPalette.primary),
                      ),
                      child: const Text(
                        'Đăng nhập ẩn danh',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.primary,
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
                          const Text(
                            'Bạn chưa có tài khoản?',
                            style: TextStyle(color: AppPalette.textMuted),
                          ),
                          GestureDetector(
                            onTap: () => _controller.toRegister(context),
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: AppPalette.primary,
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
