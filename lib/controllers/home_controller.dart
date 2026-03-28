import '../models/metric_item.dart';

class HomeController {
  const HomeController();

  List<MetricItem> getMetrics() {
    return const [
      MetricItem(
        title: 'BUOC CHAN HOM\nNAY',
        value: '6,432',
        unit: 'buoc',
        subtitle: '321 kcal\nda tieu\nthu',
      ),
      MetricItem(
        title: 'UONG NUOC',
        value: '1.2',
        unit: '/2.0L',
        subtitle: 'Muc tieu ngay',
        showProgress: true,
      ),
      MetricItem(
        title: 'CAN NANG',
        value: '65',
        unit: 'kg',
        subtitle: 'On dinh\ntrong 7 ngay\ngan day',
      ),
      MetricItem(
        title: 'GIAC NGU HOM\nNAY',
        value: '7h 30m',
        unit: '',
        subtitle: 'Chat luong: Tot\nBan da ngu du giac\nhon hom qua 35\nphut.',
        showProgress: true,
      ),
    ];
  }
}
