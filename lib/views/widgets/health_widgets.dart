import 'package:flutter/material.dart';
import '../../models/metric_item.dart';

class HealthGrid extends StatelessWidget {
  const HealthGrid({super.key, required this.metrics, this.onMetricTap});

  final List<MetricItem> metrics;
  final void Function(int index, MetricItem item)? onMetricTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1240 ? 4 : (width >= 900 ? 3 : 2);
        final childAspectRatio =
            width >= 1240 ? 1.35 : (width >= 900 ? 1.0 : 0.82);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final veryCompact = constraints.maxWidth < 130;
        final padding = veryCompact ? 8.0 : (compact ? 10.0 : 12.0);
        final titleSize = veryCompact ? 8.0 : (compact ? 9.0 : 10.0);
        final valueSize = veryCompact ? 20.0 : (compact ? 26.0 : 34.0);
        final unitSize = veryCompact ? 10.0 : 12.0;
        final subtitleSize = veryCompact ? 10.0 : 12.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
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
                  offset: const Offset(0, 6),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: titleSize,
                  ),
                ),
                SizedBox(height: veryCompact ? 4 : 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: valueSize,
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
                            fontSize: unitSize,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: veryCompact ? 4 : 8),
                Text(
                  item.subtitle,
                  maxLines: item.showProgress ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subtitleSize,
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
                      minHeight: veryCompact ? 6 : 8,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
