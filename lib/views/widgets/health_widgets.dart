import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../models/metric_item.dart';

class HealthGrid extends StatelessWidget {
  const HealthGrid({super.key, required this.metrics});

  final List<MetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: metrics
          .map((item) => MetricCard(item: item))
          .toList(growable: false),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.item});

  final MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F7F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F3A2E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 38,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.textMain,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item.unit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            style: const TextStyle(color: AppPalette.textMuted, height: 1.2),
          ),
          if (item.showProgress) ...[
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 0.6,
                minHeight: 8,
                color: AppPalette.primary,
                backgroundColor: AppPalette.divider,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
