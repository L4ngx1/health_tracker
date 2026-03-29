import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';
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
        content: Text(
          error ?? 'Đã gửi lại email xác minh. Vui lòng kiểm tra hộp thư.',
        ),
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
      ).showSnackBar(const SnackBar(content: Text('Email đã được xác minh.')));
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vẫn chưa xác minh. Vui lòng kiểm tra email.'),
      ),
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
                const Text(
                  'Sống Khỏe',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.textMain,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Email chưa xác minh',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202936),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng kiểm tra email và làm theo hướng dẫn để xác minh.',
                  style: const TextStyle(color: AppPalette.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã gửi đến: $email',
                  style: const TextStyle(color: AppPalette.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  text: 'Gửi lại email xác minh',
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
                      side: const BorderSide(color: AppPalette.primary),
                    ),
                    child: const Text('Tôi đã xác minh - Kiểm tra lại'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _signOut, child: const Text('Đăng xuất')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
