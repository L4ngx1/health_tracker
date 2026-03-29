import 'dart:math';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/tracking_controller.dart';
import '../../main.dart';
import '../../core/theme/app_palette.dart';
import '../../models/metric_item.dart';
import '../widgets/common_widgets.dart';
import '../widgets/health_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastGoalNotifyDate;
  static const HomeController _homeController = HomeController();
  static const double _defaultStepGoal = 8000;
  static const double _defaultDistanceGoalKm = 6;
  late final TrackingController _trackingController;

  @override
  void initState() {
    super.initState();
    _trackingController = TrackingController();
    _trackingController.start();
    _trackingController.registerBackgroundTracking();
    _lastGoalNotifyDate = null;
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staticMetrics = _homeController.getMetrics();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EC), Color(0xFFF2F8F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: 'Sống Khỏe\ncùng bạn'),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B7D5B), Color(0xFF0E5C41)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F3A2E),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG QUAN SỨC KHỎE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tuyệt vời! Bạn\nđang đi đúng\nhướng.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Hôm nay bạn đã giữ nhịp sinh hoạt\nđều và ngủ khá tốt.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              ValueListenableBuilder<TrackingSnapshot>(
                valueListenable: _trackingController.snapshot,
                builder: (context, snapshot, _) {
                  _checkAndNotifyGoal(snapshot);
                  void _checkAndNotifyGoal(TrackingSnapshot snapshot) async {
                    final isStepGoal = snapshot.goalType == DailyGoalType.steps;
                    final currentValue = isStepGoal
                        ? snapshot.steps.toDouble()
                        : snapshot.distanceMeters / 1000.0;
                    final goalValue = snapshot.goalValue;
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    if (_lastGoalNotifyDate == today) return;
                    if (goalValue > 0 && currentValue >= goalValue) {
                      _lastGoalNotifyDate = today;
                      final goalText = isStepGoal
                          ? '${goalValue.toInt()} bước'
                          : '${goalValue.toStringAsFixed(1)} km';
                      await flutterLocalNotificationsPlugin.show(
                        1001,
                        'Chúc mừng! 🎉',
                        'Bạn đã hoàn thành mục tiêu $goalText hôm nay.',
                        const NotificationDetails(
                          android: AndroidNotificationDetails(
                            'goal_channel',
                            'Mục tiêu ngày',
                            channelDescription:
                                'Thông báo khi hoàn thành mục tiêu ngày',
                            importance: Importance.max,
                            priority: Priority.high,
                            icon: '@mipmap/ic_launcher',
                          ),
                        ),
                      );
                    }
                  }

                  final isStepGoal = snapshot.goalType == DailyGoalType.steps;
                  final stepText = snapshot.steps.toString();
                  final distanceKm = snapshot.distanceMeters / 1000.0;
                  final distanceText = distanceKm.toStringAsFixed(2);
                  final sleepHours = snapshot.sleepMinutes ~/ 60;
                  final sleepRemaining = snapshot.sleepMinutes % 60;
                  final sleepText = '${sleepHours}h ${sleepRemaining}m';

                  final stepMetric = MetricItem(
                    title: 'BƯỚC CHÂN HÔM NAY',
                    value: stepText,
                    unit: 'bước',
                    subtitle: isStepGoal
                        ? 'Mục tiêu: ${snapshot.goalValue.toInt()} bước/ngày.'
                        : 'Đếm bước chân từ cảm biến phần cứng TYPE_STEP_COUNTER.',
                  );

                  final distanceMetric = MetricItem(
                    title: 'QUÃNG ĐƯỜNG HÔM NAY',
                    value: distanceText,
                    unit: 'km',
                    subtitle: !isStepGoal
                        ? 'Mục tiêu: ${snapshot.goalValue.toStringAsFixed(1)} km/ngày.'
                        : 'Sử dụng GPS để tính quãng đường di chuyển hôm nay.',
                  );

                  final sleepMetric = MetricItem(
                    title: 'GIẤC NGỦ HÔM NAY',
                    value: sleepText,
                    unit: '',
                    subtitle: snapshot.isSleeping
                        ? 'Đang nghỉ ngơi - phát hiện đứng yên lâu.'
                        : 'Ước lượng từ cảm biến gia tốc.',
                    showProgress: true,
                  );

                  final otherMetrics = staticMetrics.length > 1
                      ? staticMetrics.sublist(1)
                      : <MetricItem>[];
                  if (otherMetrics.isNotEmpty) {
                    otherMetrics[otherMetrics.length - 1] = sleepMetric;
                  } else {
                    otherMetrics.add(sleepMetric);
                  }

                  return Column(
                    children: [
                      _buildDailyGoalCard(snapshot),
                      const SizedBox(height: 10),
                      HealthGrid(
                        metrics: [stepMetric, distanceMetric, ...otherMetrics],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Khám phá thêm',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.textMain,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE7F1EC),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: AppPalette.primaryDark,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LUYỆN TẬP',
                            style: TextStyle(
                              color: AppPalette.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '10 phút Yoga\nsáng',
                            style: TextStyle(
                              fontSize: 32,
                              height: 0.95,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Thư giãn cơ thể và bắt\nđầu ngày mới nhẹ nhàng',
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE4EFEA),
                      child: Icon(
                        Icons.chevron_right,
                        color: AppPalette.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard(TrackingSnapshot snapshot) {
    final isStepGoal = snapshot.goalType == DailyGoalType.steps;
    final currentValue = isStepGoal
        ? snapshot.steps.toDouble()
        : snapshot.distanceMeters / 1000.0;
    final goalValue = snapshot.goalValue;
    final progress = goalValue <= 0
        ? 0.0
        : (currentValue / goalValue).clamp(0.0, 1.0);
    final remaining = max(0.0, goalValue - currentValue);

    final goalLabel = isStepGoal
        ? '${goalValue.toInt()} bước/ngày'
        : '${goalValue.toStringAsFixed(1)} km/ngày';
    final remainingLabel = isStepGoal
        ? '${remaining.toInt()} bước còn lại'
        : '${remaining.toStringAsFixed(1)} km còn lại';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MỤC TIÊU HÔM NAY',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Số bước'),
                selected: isStepGoal,
                onSelected: (selected) {
                  if (!selected || isStepGoal) return;
                  _trackingController.setDailyGoal(
                    type: DailyGoalType.steps,
                    value: _defaultStepGoal,
                  );
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('KM'),
                selected: !isStepGoal,
                onSelected: (selected) {
                  if (!selected || !isStepGoal) return;
                  _trackingController.setDailyGoal(
                    type: DailyGoalType.distanceKm,
                    value: _defaultDistanceGoalKm,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu: $goalLabel',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (isStepGoal)
            GestureDetector(
              onTap: () => _showStepGoalPicker(context, snapshot.goalValue),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.goalValue.toInt()} bước',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            )
          else
            Slider(
              value: goalValue,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${goalValue.toStringAsFixed(1)} km',
              onChanged: (value) {
                _trackingController.setDailyGoal(
                  type: snapshot.goalType,
                  value: value,
                );
              },
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 9),
          ),
          const SizedBox(height: 6),
          Text(
            progress >= 1
                ? 'Bạn đã hoàn thành mục tiêu hôm nay.'
                : remainingLabel,
            style: const TextStyle(color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }

  void _showStepGoalPicker(BuildContext context, double currentGoal) {
    final min = 1000;
    final max = 30000;
    final step = 100;
    final count = ((max - min) ~/ step) + 1;
    final initialIndex = ((currentGoal - min) ~/ step).clamp(0, count - 1);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 18, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Đặt mục tiêu số bước',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  itemExtent: 48,
                  magnification: 1.2,
                  useMagnifier: true,
                  backgroundColor: Colors.transparent,
                  onSelectedItemChanged: (index) {
                    final value = min + index * step;
                    _trackingController.setDailyGoal(
                      type: DailyGoalType.steps,
                      value: value.toDouble(),
                    );
                  },
                  children: List.generate(count, (i) {
                    final value = min + i * step;
                    return Center(
                      child: Text(
                        value.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Xong',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
