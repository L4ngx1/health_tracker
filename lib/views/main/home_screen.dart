import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/tracking_controller.dart';
import '../../core/routes/app_routes.dart';
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
  static const HomeController _homeController = HomeController();
  late final TrackingController _trackingController;

  @override
  void initState() {
    super.initState();
    _trackingController = TrackingController();
    _trackingController.start();
    _trackingController.registerBackgroundTracking();
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
              TopBar(
              title: 'Sống Khỏe\ncùng bạn',
              onProfileTap: () {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              },
            ),
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
                    subtitle:
                        'Đếm bước chân từ cảm biến phần cứng TYPE_STEP_COUNTER.',
                  );

                  final distanceMetric = MetricItem(
                    title: 'QUÃNG ĐƯỜNG HÔM NAY',
                    value: distanceText,
                    unit: 'km',
                    subtitle:
                        'Sử dụng GPS để tính quãng đường di chuyển hôm nay.',
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

                  return HealthGrid(
                    metrics: [stepMetric, distanceMetric, ...otherMetrics],
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
}
