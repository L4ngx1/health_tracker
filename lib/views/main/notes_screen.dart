import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: AppStrings.notesScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 46,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppStrings.tapToRecord(context),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppStrings.notesPrompt(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.notesContentTitle(context),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.autoDetect(context),
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        Icon(Icons.auto_awesome, color: colorScheme.primary),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(AppStrings.notePlaceholder(context)),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChipLabel(AppStrings.tagHealth(context)),
                        ChipLabel(AppStrings.tagDaily(context)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      title: AppStrings.quickMealTitle(context),
                      subtitle: AppStrings.quickMealSubtitle(context),
                      icon: Icons.restaurant_menu,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: QuickActionCard(
                      title: AppStrings.quickMoodTitle(context),
                      subtitle: AppStrings.quickMoodSubtitle(context),
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
