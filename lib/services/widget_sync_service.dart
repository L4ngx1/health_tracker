import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static final WidgetSyncService instance = WidgetSyncService._();
  static const MethodChannel _channel = MethodChannel(
    'health_tracker/widget_sync',
  );

  Future<void> syncDistanceCard({
    required int steps,
    required double distanceKm,
    required int calories,
    required double goalKm,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    try {
      final now = DateTime.now();
      final dayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _channel
          .invokeMethod<void>('updateDistanceWidget', <String, dynamic>{
        'steps': steps,
        'distanceKm': distanceKm,
        'calories': calories,
        'goalKm': goalKm,
        'dayKey': dayKey,
      });
    } catch (_) {
      // Widget sync should never break app flow.
    }
  }
}
