import 'package:flutter/material.dart';

import '../../controllers/workout_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final AIController _aiController = AIController();
  String? _aiWorkoutPlan;
  bool _isLoading = false;

  Future<void> _getAIWorkout() async {
    setState(() => _isLoading = true);
    // In real app, get these from user data
    final plan = await _aiController.getPersonalizedWorkout(
      "Build muscle and improve stamina",
      "Beginner, works out 2 times/week",
    );
    setState(() {
      _aiWorkoutPlan = plan;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const controller = WorkoutController();
    final programs = controller.getPrograms();
    final history = controller.getHistory();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EC), Color(0xFFF2F8F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Tập luyện',
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF23B56F), Color(0xFF0EA15F)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F3A2E),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mục tiêu tuần này',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '4/5 Buổi tập',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1,240 kcal đã đốt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Workout Suggestion Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppPalette.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.orangeAccent),
                        SizedBox(width: 8),
                        Text(
                          'Gợi ý luyện tập AI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_aiWorkoutPlan != null)
                      Text(_aiWorkoutPlan!)
                    else
                      const Text('Nhấn để nhận lịch tập cá nhân hóa từ AI'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _getAIWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tạo lịch tập với AI'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chế độ tập luyện',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TẤT CẢ',
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
                'Lịch sử tập luyện',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
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
      ),
    );
  }
}
