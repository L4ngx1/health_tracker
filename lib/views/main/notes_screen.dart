import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EC), Color(0xFFF1F7F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: 'Ghi chú sức khỏe - Sống Khỏe'),
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
                  'Nhấn để ghi âm',
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
                  'Nói về tình trạng sức khỏe, chế độ ăn\nhoặc cảm xúc hôm nay của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'NỘI DUNG GHI CHÚ',
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
                  color: AppPalette.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1B7D5B),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tự động nhận diện',
                          style: TextStyle(color: AppPalette.textMuted),
                        ),
                        Icon(Icons.auto_awesome, color: AppPalette.primaryDark),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Bắt đầu nói để thấy nội dung ghi chú\nxuất hiện tại đây...',
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
                      title: 'Bữa ăn',
                      subtitle: 'Ghi lại dinh dưỡng',
                      icon: Icons.restaurant_menu,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: QuickActionCard(
                      title: 'Cảm xúc',
                      subtitle: 'Theo dõi tâm trạng',
                      icon: Icons.sentiment_satisfied_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
