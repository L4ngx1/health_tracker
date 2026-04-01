import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/metric_item.dart';

class HomeController {
  const HomeController();

  List<MetricItem> getMetrics(BuildContext context) {
    return [
      MetricItem(
        title: AppStrings.homeMetricStepsTitle(context),
        value: '6,432',
        unit: AppStrings.homeMetricStepsUnit(context),
        subtitle: AppStrings.homeMetricStepsSubtitle(context),
      ),
      MetricItem(
        title: AppStrings.homeMetricWaterTitle(context),
        value: '1.2',
        unit: '/2.0L',
        subtitle: AppStrings.homeMetricWaterSubtitle(context),
        showProgress: true,
      ),
      MetricItem(
        title: AppStrings.homeMetricWeightTitle(context),
        value: '65',
        unit: 'kg',
        subtitle: AppStrings.homeMetricWeightSubtitle(context),
      ),
      MetricItem(
        title: AppStrings.homeMetricSleepTodayTitle(context),
        value: '7h 30m',
        unit: '',
        subtitle: AppStrings.homeMetricSleepTodaySubtitle(context),
        showProgress: true,
      ),
    ];
  }
}
