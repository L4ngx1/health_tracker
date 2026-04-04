import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/metric_item.dart';
import '../models/backend/weight_record.dart';
import '../services/backend_api_service.dart';

class HomeController {
  HomeController({BackendApiService? backendApiService})
    : _backendApiService = backendApiService ?? BackendApiService();

  final BackendApiService _backendApiService;

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

  Future<double?> getLatestWeightKg() async {
    try {
      final records = await _backendApiService.getMyWeightRecords(limit: 1);
      if (records.isEmpty) return null;
      return records.first.weightKg;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWeightKg(double value) async {
    final record = WeightRecord(
      id: '',
      weightKg: value,
      recordedAt: DateTime.now(),
    );
    await _backendApiService.addMyWeightRecord(record);
  }
}
