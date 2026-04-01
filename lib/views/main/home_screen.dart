import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/tracking_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../../models/metric_item.dart';
import '../../services/health_cloud_sync_service.dart';
import '../../services/widget_sync_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/health_widgets.dart';
import 'sleep_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const HomeController _homeController = HomeController();
  static const _prefGoalKm = 'home.movementGoalKm';
  static const _prefDistanceHistory = 'home.distanceHistoryKm';
  static const _prefMigrationDone = 'home.migration.v1';
  static const _prefTodayResetDone = 'home.movementTodayResetDone';
  static const _manualResetTestDay = '2026-03-30';
  static const _manualResetVersion = 'r2';

  late final TrackingController _trackingController;
  final HealthCloudSyncService _cloudSync = HealthCloudSyncService();
  SharedPreferences? _prefs;
  DateTime? _lastCloudConfigSyncAt;
  double _dailyGoalKm = 6.0;
  final Map<String, double> _distanceHistoryKm = <String, double>{};
  bool _promptedLocationPermission = false;

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _accountKey(String base) => '$base.$_userScope';
  String get _migrationKey => '$_prefMigrationDone.$_userScope';

  String? get _cloudUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _migrateLegacyMovementIfNeeded() async {
    if (_prefs == null) return;
    if (_prefs!.getBool(_migrationKey) == true) return;

    final scopedGoalKey = _accountKey(_prefGoalKm);
    final scopedHistoryKey = _accountKey(_prefDistanceHistory);
    final hasScoped =
        _prefs!.containsKey(scopedGoalKey) ||
        _prefs!.containsKey(scopedHistoryKey);

    if (!hasScoped) {
      if (_prefs!.containsKey(_prefGoalKm)) {
        final legacyGoal = _prefs!.getDouble(_prefGoalKm);
        if (legacyGoal != null) {
          await _prefs!.setDouble(scopedGoalKey, legacyGoal);
        }
      }
      if (_prefs!.containsKey(_prefDistanceHistory)) {
        final legacyHistory = _prefs!.getString(_prefDistanceHistory);
        if (legacyHistory != null && legacyHistory.isNotEmpty) {
          await _prefs!.setString(scopedHistoryKey, legacyHistory);
        }
      }
    }

    await _prefs!.setBool(_migrationKey, true);
  }

  @override
  void initState() {
    super.initState();
    _trackingController = TrackingController();
    _trackingController.start();
    _trackingController.registerBackgroundTracking();
    _trackingController.snapshot.addListener(_syncTodayDistanceHistory);
    unawaited(_initializeMovementData());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeRequestLocationPermission());
    });
  }

  Future<void> _maybeRequestLocationPermission() async {
    if (!mounted || _promptedLocationPermission) return;
    _promptedLocationPermission = true;

    var permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
    }

    if (permission == LocationPermission.deniedForever) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Cần quyền vị trí'),
            content: const Text(
              'Bạn đã tắt quyền vị trí vĩnh viễn (Don\'t ask again).\n'
              'Vui lòng vào Cài đặt để bật lại quyền Vị trí để tính quãng đường.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Để sau'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Geolocator.openAppSettings();
                },
                child: const Text('Mở cài đặt'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _initializeMovementData() async {
    await _loadMovementConfig();
    await _resetTodayMovementForTestingOnce();
  }

  @override
  void dispose() {
    _trackingController.snapshot.removeListener(_syncTodayDistanceHistory);
    _trackingController.dispose();
    super.dispose();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _todayResetKey(DateTime dt) =>
      '${_accountKey(_prefTodayResetDone)}.${_dayKey(dt)}.$_manualResetVersion';

  String _shortDayLabel(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

  String _formatNumber(num value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  Future<void> _loadMovementConfig() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _migrateLegacyMovementIfNeeded();
    _dailyGoalKm = _prefs?.getDouble(_accountKey(_prefGoalKm)) ?? 6.0;
    final historyRaw = _prefs?.getString(_accountKey(_prefDistanceHistory));
    _distanceHistoryKm.clear();
    if (historyRaw != null && historyRaw.isNotEmpty) {
      final decoded = jsonDecode(historyRaw);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is num) {
            _distanceHistoryKm[entry.key] = value.toDouble();
          }
        }
      }
    }

    final uid = _cloudUid;
    if (uid != null) {
      try {
        final cloud = await _cloudSync.loadMovementConfig(uid: uid);
        if (cloud != null) {
          if (cloud.dailyGoalKm != null) {
            _dailyGoalKm = cloud.dailyGoalKm!;
          }
          if (cloud.distanceHistoryKm != null) {
            _distanceHistoryKm
              ..clear()
              ..addAll(cloud.distanceHistoryKm!);
          }
          await _prefs?.setDouble(_accountKey(_prefGoalKm), _dailyGoalKm);
          await _prefs?.setString(
            _accountKey(_prefDistanceHistory),
            jsonEncode(_distanceHistoryKm),
          );
        }
      } catch (e) {
        debugPrint('Cloud load movement config failed: $e');
      }
    }

    await _persistMovementConfig(forceCloud: true);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resetTodayMovementForTestingOnce() async {
    _prefs ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    if (_dayKey(now) != _manualResetTestDay) {
      return;
    }
    final resetKey = _todayResetKey(now);
    final alreadyReset = _prefs?.getBool(resetKey) ?? false;
    if (alreadyReset) {
      return;
    }

    await _trackingController.resetTodayMovement();
    _distanceHistoryKm[_dayKey(now)] = 0;
    await _persistMovementConfig(forceCloud: true);
    await _prefs?.setBool(resetKey, true);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _persistMovementConfig({bool forceCloud = false}) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setDouble(_accountKey(_prefGoalKm), _dailyGoalKm);
    await _prefs?.setString(
      _accountKey(_prefDistanceHistory),
      jsonEncode(_distanceHistoryKm),
    );

    final uid = _cloudUid;
    if (uid != null) {
      final now = DateTime.now();
      if (forceCloud ||
          _lastCloudConfigSyncAt == null ||
          now.difference(_lastCloudConfigSyncAt!) >
              const Duration(seconds: 8)) {
        _lastCloudConfigSyncAt = now;
        unawaited(
          _cloudSync
              .saveMovementConfig(
                uid: uid,
                dailyGoalKm: _dailyGoalKm,
                distanceHistoryKm: Map<String, double>.from(_distanceHistoryKm),
              )
              .catchError((Object e) {
                debugPrint('Cloud save movement config failed: $e');
              }),
        );
      }
    }

    final snapshot = _trackingController.snapshot.value;
    final distanceKm = snapshot.distanceMeters / 1000.0;
    final steps = snapshot.steps;
    final calories = (distanceKm * 55).round();
    unawaited(
      WidgetSyncService.instance.syncDistanceCard(
        steps: steps,
        distanceKm: distanceKm,
        calories: calories,
        goalKm: _dailyGoalKm,
      ),
    );
  }

  void _trimHistory() {
    if (_distanceHistoryKm.length <= 30) {
      return;
    }
    final sortedKeys = _distanceHistoryKm.keys.toList()..sort();
    final removeCount = sortedKeys.length - 30;
    for (var i = 0; i < removeCount; i++) {
      _distanceHistoryKm.remove(sortedKeys[i]);
    }
  }

  void _syncTodayDistanceHistory() {
    if (_prefs == null) {
      return;
    }
    final today = _dayKey(DateTime.now());
    final todayKm = _trackingController.snapshot.value.distanceMeters / 1000.0;
    final previous = _distanceHistoryKm[today] ?? 0;
    if ((todayKm - previous).abs() < 0.01) {
      return;
    }
    _distanceHistoryKm[today] = todayKm;
    _trimHistory();
    _persistMovementConfig();
  }

  List<MapEntry<DateTime, double>> _last7DaysHistory(double todayKm) {
    final now = DateTime.now();
    final map = Map<String, double>.from(_distanceHistoryKm);
    map[_dayKey(now)] = todayKm;
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      final km = map[_dayKey(day)] ?? 0;
      return MapEntry(day, km);
    });
  }

  Future<void> _showMovementSheet({
    required double distanceKm,
    required int steps,
    required int calories,
  }) async {
    var draftGoal = _dailyGoalKm;
    final history = _last7DaysHistory(distanceKm);
    var selectedIndex = history.length - 1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E4DD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mục tiêu di chuyển',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hôm nay: ${distanceKm.toStringAsFixed(2)} km • ${_formatNumber(steps)} bước • ${_formatNumber(calories)} kcal',
                      style: const TextStyle(color: AppPalette.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mục tiêu mỗi ngày: ${draftGoal.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.primaryDark,
                      ),
                    ),
                    Slider(
                      value: draftGoal,
                      min: 1,
                      max: 20,
                      divisions: 38,
                      label: '${draftGoal.toStringAsFixed(1)} km',
                      activeColor: AppPalette.primary,
                      onChanged: (value) {
                        setModalState(() {
                          draftGoal = value;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Lịch sử 7 ngày gần nhất',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: history.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final day = history[index].key;
                          final km = history[index].value;
                          final ratio = (km / draftGoal).clamp(0.0, 1.0);
                          final isSelected = index == selectedIndex;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setModalState(() {
                                selectedIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEAF6F0)
                                    : const Color(0xFFF7FAF8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppPalette.primary
                                      : const Color(0xFFE1ECE6),
                                  width: isSelected ? 1.4 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _shortDayLabel(day),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? AppPalette.primaryDark
                                              : AppPalette.textMain,
                                        ),
                                      ),
                                      Text(
                                        '${km.toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                          color: AppPalette.primaryDark,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 8,
                                      backgroundColor: const Color(0xFFDCE9E2),
                                      color: isSelected
                                          ? AppPalette.primaryDark
                                          : AppPalette.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final selectedDay = history[selectedIndex].key;
                        final selectedKm = history[selectedIndex].value;
                        final isToday =
                            _dayKey(selectedDay) == _dayKey(DateTime.now());
                        final selectedSteps = isToday
                            ? steps
                            : ((selectedKm * 1000) / 0.78).round();
                        final selectedCalories = (selectedKm * 55).round();
                        final selectedPercent = draftGoal <= 0
                            ? 0
                            : ((selectedKm / draftGoal) * 100)
                                  .clamp(0.0, 999.0)
                                  .round();

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE1ECE6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Thống kê ${_shortDayLabel(selectedDay)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.primaryDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD5F2E2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$selectedPercent% mục tiêu',
                                      style: const TextStyle(
                                        color: AppPalette.primaryDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCell(
                                      label: 'QUÃNG ĐƯỜNG',
                                      value: selectedKm.toStringAsFixed(2),
                                      unit: 'km',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatCell(
                                      label: 'BƯỚC CHÂN',
                                      value: _formatNumber(selectedSteps),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatCell(
                                      label: 'CALO',
                                      value: _formatNumber(selectedCalories),
                                      unit: 'kcal',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 90,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(history.length, (
                                    index,
                                  ) {
                                    final day = history[index].key;
                                    final km = history[index].value;
                                    final selected = index == selectedIndex;
                                    final ratio = draftGoal <= 0
                                        ? 0.0
                                        : (km / draftGoal).clamp(0.0, 1.0);
                                    final barHeight = 18.0 + (ratio * 52.0);
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              height: barHeight,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? AppPalette.primary
                                                    : const Color(0xFFD7E1DD),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: selected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: selected
                                                    ? AppPalette.primaryDark
                                                    : AppPalette.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _dailyGoalKm = draftGoal;
                          });
                          _persistMovementConfig(forceCloud: true);
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Lưu mục tiêu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    String? unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.textMain,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.primaryDark,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
                title: 'Sống khỏe cùng bạn',
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
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
                  final distanceKm = snapshot.distanceMeters / 1000.0;
                  final distanceText = distanceKm.toStringAsFixed(2);
                  final estimatedSteps = snapshot.steps;
                  final estimatedCalories = (distanceKm * 55).round();
                  final sleepHours = snapshot.sleepMinutes ~/ 60;
                  final sleepRemaining = snapshot.sleepMinutes % 60;
                  final sleepText = '${sleepHours}h ${sleepRemaining}m';

                  final distanceMetric = MetricItem(
                    title: 'QUÃNG ĐƯỜNG HÔM NAY',
                    value: distanceText,
                    unit: 'km',
                    subtitle:
                        '${_formatNumber(estimatedSteps)} bước\n${_formatNumber(estimatedCalories)} kcal\nMục tiêu: ${_dailyGoalKm.toStringAsFixed(1)} km/ngày',
                  );

                  final sleepMetric = MetricItem(
                    title: 'PHIÊN NGỦ GẦN NHẤT',
                    value: sleepText,
                    unit: '',
                    subtitle: snapshot.isSleeping
                        ? 'Đang ngủ (chấm điểm theo epoch + cửa sổ trượt).'
                        : 'Ước lượng từ gia tốc + bước chân theo từng phút.',
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
                    metrics: [distanceMetric, ...otherMetrics],
                    onMetricTap: (index, item) {
                      if (index == 0) {
                        _showMovementSheet(
                          distanceKm: distanceKm,
                          steps: estimatedSteps,
                          calories: estimatedCalories,
                        );
                        return;
                      }

                      if (item.title.toUpperCase().contains('GIẤC NGỦ')) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SleepManagementScreen(
                              trackingController: _trackingController,
                            ),
                          ),
                        );
                      }
                    },
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
