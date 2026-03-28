import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: 'Ghi chu suc khoe - Song Khoe'),
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: AppPalette.primary,
                child: Icon(
                  Icons.mic_none_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Nhan de ghi am',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Noi ve tinh trang suc khoe, che do an\nhoac cam xuc hom nay cua ban.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'NOI DUNG GHI CHU',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppPalette.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF0F3F1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tu dong nhan dien',
                        style: TextStyle(color: AppPalette.textMuted),
                      ),
                      Icon(Icons.auto_awesome, color: AppPalette.primaryDark),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Bat dau noi de thay noi dung ghi chu\nxuat hien tai day...',
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [ChipLabel('#HEALTH'), ChipLabel('#DAILY')],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    title: 'Bua an',
                    subtitle: 'Ghi lai dinh duong',
                    icon: Icons.restaurant_menu,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: QuickActionCard(
                    title: 'Cam xuc',
                    subtitle: 'Theo doi tam trang',
                    icon: Icons.sentiment_satisfied_alt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
