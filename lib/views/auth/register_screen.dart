import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const controller = AuthController();

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F3EC), Color(0xFFF1F7F3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => controller.toLogin(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppPalette.textMain,
                        ),
                      ),
                      const Text(
                        'Sống Khỏe',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const BrandIconOnly(),
                  const SizedBox(height: 16),
                  const Text(
                    'BẮT ĐẦU HÀNH TRÌNH',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.primaryDark,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đăng ký tài khoản',
                    style: TextStyle(
                      fontSize: 44,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF202936),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tham gia cộng đồng sống khỏe để bắt đầu\ntheo dõi và cải thiện sức khỏe mỗi ngày.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.textMuted,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const InputLabel('Họ và tên'),
                  const SizedBox(height: 10),
                  const RoundedInput(
                    hint: 'Nguyễn Văn A',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  const InputLabel('Số điện thoại / Email'),
                  const SizedBox(height: 10),
                  const RoundedInput(
                    hint: 'example@gmail.com',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  const InputLabel('Mật khẩu'),
                  const SizedBox(height: 10),
                  const RoundedInput(
                    hint: '................',
                    icon: Icons.visibility_off_outlined,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Đăng ký',
                    onPressed: () => controller.signup(context),
                  ),
                  const SizedBox(height: 22),
                  const DividerWithText(text: 'HOẶC'),
                  const SizedBox(height: 20),
                  SocialButton(
                    text: 'Tiếp tục với Google',
                    onPressed: () => controller.continueWithGoogle(
                      context,
                      clearStack: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Bạn đã có tài khoản? ',
                          style: TextStyle(color: AppPalette.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => controller.toLogin(context),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
