import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';
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
                        'Đăng ký tài khoản',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202936),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tham gia cộng đồng sống khỏe để bắt đầu theo dõi và cải thiện sức khỏe mỗi ngày.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppPalette.textMuted,
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
                  const SizedBox(height: 18),
                  const InputLabel('Họ và tên'),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _nameController,
                    hint: 'Nguyễn Văn A',
                    icon: Icons.person_outline,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocus),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const InputLabel('Email'),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _userController,
                    hint: 'example@gmail.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 12),
                  const InputLabel('Mật khẩu'),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _passwordController,
                    hint: 'Nhập mật khẩu',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_confirmFocus),
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
                  const SizedBox(height: 12),
                  const InputLabel('Xác nhận mật khẩu'),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _confirmPasswordController,
                    hint: 'Nhập lại mật khẩu',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    focusNode: _confirmFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Đăng ký',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  const DividerWithText(text: 'HOẶC'),
                  const SizedBox(height: 14),
                  SocialButton(
                    text: 'Tiếp tục với Google',
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
                          const Text(
                            'Bạn đã có tài khoản? ',
                            style: TextStyle(color: AppPalette.textMuted),
                          ),
                          GestureDetector(
                            onTap: () => _controller.toLogin(context),
                            child: const Text(
                              'Đăng nhập',
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
