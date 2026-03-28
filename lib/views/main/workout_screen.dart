import 'package:flutter/material.dart';

import '../../controllers/workout_controller.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const controller = WorkoutController();
    final programs = controller.getPrograms();
    final history = controller.getHistory();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: 'Tap luyen - Song Khoe'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF23B56F), Color(0xFF0EA15F)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muc tieu tuan nay',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '4/5 Buoi tap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1,240 kcal da dot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Che do tap luyen',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
                ),
                Text(
                  'TAT CA',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppPalette.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: programs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, index) => WorkoutCard(item: programs[index]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lich su tap\nluyen',
              style: TextStyle(
                fontSize: 40,
                height: 0.9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...history.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HistoryTile(item: entry),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
