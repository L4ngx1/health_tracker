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
                      'Song Khoe',
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
                  'BAT DAU HANH TRINH',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.primaryDark,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dang ky tai khoan',
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
                  'Tham gia cong dong song khoe de bat dau\ntheo doi va cai thien suc khoe moi ngay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                const InputLabel('Ho va ten'),
                const SizedBox(height: 10),
                const RoundedInput(
                  hint: 'Nguyen Van A',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                const InputLabel('So dien thoai / Email'),
                const SizedBox(height: 10),
                const RoundedInput(
                  hint: 'example@gmail.com',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 14),
                const InputLabel('Mat khau'),
                const SizedBox(height: 10),
                const RoundedInput(
                  hint: '................',
                  icon: Icons.visibility_off_outlined,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Dang ky',
                  onPressed: () => controller.signup(context),
                ),
                const SizedBox(height: 22),
                const DividerWithText(text: 'HOAC'),
                const SizedBox(height: 20),
                SocialButton(
                  text: 'Tiep tuc voi Google',
                  onPressed: () =>
                      controller.continueWithGoogle(context, clearStack: true),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Ban da co tai khoan? ',
                        style: TextStyle(color: AppPalette.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => controller.toLogin(context),
                        child: const Text(
                          'Dang nhap',
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
