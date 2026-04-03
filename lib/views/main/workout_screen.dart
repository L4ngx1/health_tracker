import 'package:flutter/material.dart';

import '../../controllers/ai_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/common_widgets.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final AIController _aiController = AIController();

  bool _isLoading = false;
  int _goalIndex = 0;
  int _levelIndex = 0;
  String _plan = '';

  static const List<(String label, String prompt)> _goalOptions = [
    ('Fat loss', 'Fat loss and better endurance'),
    ('Muscle gain', 'Muscle gain and strength improvement'),
    ('Endurance', 'Cardio endurance and stamina improvement'),
    ('Maintain', 'Maintain general fitness'),
  ];

  static const List<(String label, String prompt)> _levelOptions = [
    ('Beginner', 'Beginner level, 2 sessions/week'),
    ('Intermediate', 'Intermediate level, 3-4 sessions/week'),
    ('Advanced', 'Advanced level, 5 sessions/week'),
  ];

  Future<void> _generatePlan() async {
    setState(() => _isLoading = true);
    try {
      final plan = await _aiController.getPersonalizedWorkout(
        _goalOptions[_goalIndex].$2,
        _levelOptions[_levelIndex].$2,
      );
      if (!mounted) return;
      setState(() => _plan = plan.trim());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: AppStrings.workoutScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 16),
              Text('Goal', style: TextStyle(fontWeight: FontWeight.w700)),
              DropdownButton<int>(
                isExpanded: true,
                value: _goalIndex,
                items: List.generate(
                  _goalOptions.length,
                  (i) => DropdownMenuItem(
                      value: i, child: Text(_goalOptions[i].$1)),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _goalIndex = v);
                },
              ),
              const SizedBox(height: 8),
              Text('Level', style: TextStyle(fontWeight: FontWeight.w700)),
              DropdownButton<int>(
                isExpanded: true,
                value: _levelIndex,
                items: List.generate(
                  _levelOptions.length,
                  (i) => DropdownMenuItem(
                      value: i, child: Text(_levelOptions[i].$1)),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _levelIndex = v);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _generatePlan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Generate AI workout plan'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.surface,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _plan.isEmpty ? 'No plan generated yet.' : _plan,
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
