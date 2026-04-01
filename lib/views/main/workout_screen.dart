import 'package:flutter/material.dart';

import '../../controllers/workout_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
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
    final programs = controller.getPrograms(context);
    final history = controller.getHistory(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
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
                title: AppStrings.workoutScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.84),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.weekGoalTitle(context),
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.weekGoalProgress(context),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      AppStrings.weekGoalCalories(context),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
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
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.aiWorkoutSuggestionTitle(context),
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
                      Text(AppStrings.aiWorkoutSuggestionHint(context)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _getAIWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppStrings.aiGeneratePlanButton(context)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.programModesTitle(context),
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
                    AppStrings.allCaps(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
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
              Text(
                AppStrings.workoutHistoryTitle(context),
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
