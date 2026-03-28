import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';
import '../widgets/health_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const controller = HomeController();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: 'Song Khoe\ncung ban'),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1EA96C), Color(0xFF0E995E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TONG QUAN SUC KHOE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tuyet voi! Ban\ndang di dung\nhuong.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Hom nay ban da giu nhip sinh hoat\ndeu va ngu kha tot.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            HealthGrid(metrics: controller.getMetrics()),
            const SizedBox(height: 18),
            const Text(
              'Kham pha them',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppPalette.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFE7F1EC),
                    ),
                    child: const Icon(
                      Icons.self_improvement,
                      color: AppPalette.primaryDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LUYEN TAP',
                          style: TextStyle(
                            color: AppPalette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '10 phut Yoga\nsang',
                          style: TextStyle(
                            fontSize: 32,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text('Thu gian co the va bat\ndau ngay moi nhe nhang'),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE4EFEA),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppPalette.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
