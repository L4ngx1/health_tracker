import 'package:flutter/material.dart';

import '../../models/metric_item.dart';

class HealthGrid extends StatelessWidget {
  const HealthGrid({super.key, required this.metrics, this.onMetricTap});

  final List<MetricItem> metrics;
  final void Function(int index, MetricItem item)? onMetricTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: metrics
          .asMap()
          .entries
          .map(
            (entry) => MetricCard(
              item: entry.value,
              onTap: onMetricTap == null
                  ? null
                  : () => onMetricTap!(entry.key, entry.value),
            ),
          )
          .toList(growable: false),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.item, this.onTap});

  final MetricItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
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
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 34,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item.unit,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              maxLines: item.showProgress ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.2,
              ),
            ),
            if (item.showProgress) ...[
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: item.progress?.clamp(0.0, 1.0) ?? 0.6,
                  minHeight: 8,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.outlineVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
