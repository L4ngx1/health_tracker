import '../models/metric_item.dart';

class HomeController {
  const HomeController();

  List<MetricItem> getMetrics() {
    return const [
      MetricItem(
        title: 'BƯỚC CHÂN HÔM\nNAY',
        value: '6,432',
        unit: 'bước',
        subtitle: '321 kcal\nđã tiêu\nthụ',
      ),
      MetricItem(
        title: 'UỐNG NƯỚC',
        value: '1.2',
        unit: '/2.0L',
        subtitle: 'Mục tiêu ngày',
        showProgress: true,
      ),
      MetricItem(
        title: 'CÂN NẶNG',
        value: '65',
        unit: 'kg',
        subtitle: 'Ổn định\ntrong 7 ngày\ngần đây',
      ),
      MetricItem(
        title: 'GIẤC NGỦ HÔM\nNAY',
        value: '7h 30m',
        unit: '',
        subtitle: 'Chất lượng: Tốt\nBạn đã ngủ đủ giấc\nhơn hôm qua 35\nphút.',
        showProgress: true,
      ),
    ];
  }
}
