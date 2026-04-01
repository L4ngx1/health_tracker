import 'package:flutter/material.dart';

import '../../controllers/tracking_controller.dart';
import '../../core/localization/app_strings.dart';

class SleepManagementScreen extends StatelessWidget {
  const SleepManagementScreen({super.key, required this.trackingController});

  final TrackingController trackingController;

  String _formatSleepText(int minutes) {
    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;
    return '${hours}h ${remaining}m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.sleepManagementTitle(context))),
      body: ValueListenableBuilder<TrackingSnapshot>(
        valueListenable: trackingController.snapshot,
        builder: (context, snapshot, _) {
          final int totalMinutes = snapshot.sleepMinutes;
          final String sleepText = _formatSleepText(totalMinutes);
          final double progress = (totalMinutes / 480).clamp(0.0, 1.0);

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.lastSleepSession(context),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sleepText,
                          style: TextStyle(
                            fontSize: 42,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snapshot.isSleeping
                              ? AppStrings.currentStatusSleeping(context)
                              : AppStrings.currentStatusAwake(context),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: colorScheme.outlineVariant,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.sleepGoalReference(context),
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.sleepHowItWorksTitle(context),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(AppStrings.sleepHowBullet1(context)),
                        SizedBox(height: 4),
                        Text(AppStrings.sleepHowBullet2(context)),
                        SizedBox(height: 4),
                        Text(AppStrings.sleepHowBullet3(context)),
                        SizedBox(height: 4),
                        Text(AppStrings.sleepHowBullet4(context)),
                        SizedBox(height: 4),
                        Text(AppStrings.sleepHowBullet5(context)),
                        SizedBox(height: 4),
                        Text(AppStrings.sleepHowBullet6(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
