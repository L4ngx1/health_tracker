import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/auth_layout.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillEmail});

  final String? prefillEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = const AuthController();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _isLoading = v);
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_controller.isValidEmail(email)) {
      _setError('Vui lòng nhập email hợp lệ.');
      return;
    }

    _setError(null);
    _setLoading(true);
    final error = await _controller.forgotPassword(email);
    if (!mounted) return;
    _setLoading(false);

    if (error != null) {
      _setError(error);
      return;
    }

    _setError(null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đường link đặt lại mật khẩu đã được gửi đến hộp thư của bạn nếu email tồn tại trong hệ thống(Vui lòng kiểm tra cả mục thư rác).'),
        duration: Duration(seconds: 4),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthLayout(
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centered brand and section header (back button is provided by AuthLayout)
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
                      'Đặt lại mật khẩu',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202936),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nhập email để nhận mail đặt lại mật khẩu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppPalette.textMuted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
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
                ],
                const SizedBox(height: 16),
                const InputLabel('Email'),
                const SizedBox(height: 8),
                RoundedInput(
                  controller: _emailController,
                  hint: 'Nhập email của bạn',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Gửi',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppPalette.textMuted,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
