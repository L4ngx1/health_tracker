class MetricItem {
  const MetricItem({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    this.showProgress = false,
  });

  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final bool showProgress;
}
