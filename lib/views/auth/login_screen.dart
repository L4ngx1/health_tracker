import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const controller = AuthController();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const BrandHeader(
                  subTitle: 'Hành trình chăm sóc sức khỏe của bạn',
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const InputLabel('Số điện thoại / Email'),
                const SizedBox(height: 10),
                const RoundedInput(
                  hint: 'Nhập email hoặc số điện thoại',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                const InputLabel('Mật khẩu'),
                const SizedBox(height: 10),
                const RoundedInput(
                  hint: 'Nhập mật khẩu',
                  icon: Icons.visibility_outlined,
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Đăng nhập',
                  onPressed: () => controller.login(context),
                ),
                const SizedBox(height: 22),
                const DividerWithText(text: 'HOẶC'),
                const SizedBox(height: 22),
                SocialButton(
                  text: 'Tiếp tục với Google',
                  onPressed: () =>
                      controller.continueWithGoogle(context, clearStack: false),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Bạn chưa có tài khoản? ',
                        style: TextStyle(color: AppPalette.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => controller.toRegister(context),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
