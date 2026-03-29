import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../models/workout_history_item.dart';
import '../../models/workout_item.dart';

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.item});

  final WorkoutItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE9E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F3A2E),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFBDEFD5),
            child: Icon(item.icon, color: AppPalette.primaryDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.item});

  final WorkoutHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF2EE),
            child: Icon(Icons.directions_run, color: AppPalette.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.date} • ${item.duration}',
                  style: const TextStyle(color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.kcal,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppPalette.primaryDark,
                  fontSize: 30,
                ),
              ),
              const Text(
                'KCAL',
                style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF16995F), Color(0xFF118A58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
