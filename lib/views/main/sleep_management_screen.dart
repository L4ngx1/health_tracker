import 'package:flutter/material.dart';

import '../../controllers/tracking_controller.dart';
import '../../core/theme/app_palette.dart';

class SleepManagementScreen extends StatelessWidget {
  const SleepManagementScreen({super.key, required this.trackingController});

  final TrackingController trackingController;

  String _formatSleepText(int minutes) {
    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;
    return '${hours}h ${remaining}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý giấc ngủ')),
      body: ValueListenableBuilder<TrackingSnapshot>(
        valueListenable: trackingController.snapshot,
        builder: (context, snapshot, _) {
          final int totalMinutes = snapshot.sleepMinutes;
          final String sleepText = _formatSleepText(totalMinutes);
          final double progress = (totalMinutes / 480).clamp(0.0, 1.0);

          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F3EC), Color(0xFFF2F8F4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                        const Text(
                          'Phiên ngủ gần nhất',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.textMain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sleepText,
                          style: const TextStyle(
                            fontSize: 42,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snapshot.isSleeping
                              ? 'Trạng thái hiện tại: Đang ngủ'
                              : 'Trạng thái hiện tại: Đang thức',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFDCE9E2),
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mục tiêu tham chiếu: 8h mỗi ngày',
                          style: TextStyle(color: AppPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDE2CD)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cách hệ thống đo giấc ngủ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textMain,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '- Dữ liệu gia tốc được gom theo từng khung 1 phút (epoch).',
                        ),
                        SizedBox(height: 4),
                        Text(
                          '- Mỗi phút tạo Activity Score từ số lần chuyển động vượt ngưỡng.',
                        ),
                        SizedBox(height: 4),
                        Text(
                          '- Hệ thống dùng cửa sổ trượt có trọng số để phân loại ngủ/thức từng phút.',
                        ),
                        SizedBox(height: 4),
                        Text(
                          '- Nếu bước chân trong phút hiện tại cao, phút đó được ưu tiên xếp vào trạng thái thức.',
                        ),
                        SizedBox(height: 4),
                        Text(
                          '- Kết quả hiển thị có độ trễ khoảng 1 phút vì cần dữ liệu phút kế tiếp để chấm điểm.',
                        ),
                        SizedBox(height: 4),
                        Text(
                          '- Dữ liệu mang tính tham khảo, có thể lệch khi điện thoại không đặt gần cơ thể lúc ngủ.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
