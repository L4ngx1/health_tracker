import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/tracking_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/metric_item.dart';
import '../../models/sleep_session.dart';
import '../../services/backend_api_service.dart';
import '../../services/health_cloud_sync_service.dart';
import '../../services/journal_note_service.dart';
import '../../services/hydration_notification_service.dart';
import '../../services/permission_queue.dart';
import '../../services/widget_sync_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/health_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _homeController = HomeController();
  static const _prefGoalKm = 'home.movementGoalKm';
  static const _prefDistanceHistory = 'home.distanceHistoryKm';
  static const _prefMigrationDone = 'home.migration.v1';
  static const _prefTodayResetDone = 'home.movementTodayResetDone';
  static const _prefWeightKg = 'profile.weightKg';
  static const _prefWeightMigrationDone = 'profile.weight.migration.v1';
  static const _prefWeightLastUpdatedEpochMs =
      'profile.weightLastUpdatedEpochMs';
  static const _prefWeightMonthlyPromptSeenMonth =
      'profile.weightMonthlyPromptSeenMonth';
  static const _prefWaterGoalMl = 'home.waterGoalMl';
  static const _prefWaterIntakeMl = 'home.waterIntakeMl';
  static const _prefWaterDateKey = 'home.waterDateKey';
  static const _prefWaterLastDrinkEpochMs = 'home.waterLastDrinkEpochMs';
  static const _prefWaterLastReminderEpochMs = 'home.waterLastReminderEpochMs';
  static const _prefWaterReminderEnabled = 'home.waterReminderEnabled';
  static const _prefWaterManualIntervalMinutes =
      'home.waterManualIntervalMinutes';
  static const _prefNotificationsEnabled = 'notifications_enabled';
  static const _manualResetTestDay = '2026-03-30';
  static const _manualResetVersion = 'r2';

  late final TrackingController _trackingController;
  final HealthCloudSyncService _cloudSync = HealthCloudSyncService();
  final BackendApiService _backendApiService = BackendApiService();
  final JournalNoteService _journalNoteService = const JournalNoteService();
  SharedPreferences? _prefs;
  DateTime? _lastCloudConfigSyncAt;
  double _dailyGoalKm = 6.0;
  final Map<String, double> _distanceHistoryKm = <String, double>{};
  bool _didRunPermissionFlow = false;
  double? _weightKg;
  int _waterGoalMl = 2000;
  int _waterIntakeMl = 0;
  bool _waterReminderEnabled = true;
  int _waterManualIntervalMinutes = 90;
  DateTime? _lastWaterDrinkAt;
  DateTime? _lastWaterReminderAt;
  Timer? _waterReminderTimer;
  Timer? _heroBannerTimer;
  final PageController _heroBannerController = PageController();
  int _heroBannerIndex = 0;
  final PageController _explorePageController = PageController(
    viewportFraction: 0.94,
  );
  int _explorePageIndex = 0;

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _accountKey(String base) => '$base.$_userScope';
  String get _migrationKey => '$_prefMigrationDone.$_userScope';
  String get _weightMigrationKey => '$_prefWeightMigrationDone.$_userScope';

  String? get _cloudUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _migrateLegacyMovementIfNeeded() async {
    if (_prefs == null) return;
    if (_prefs!.getBool(_migrationKey) == true) return;

    final scopedGoalKey = _accountKey(_prefGoalKm);
    final scopedHistoryKey = _accountKey(_prefDistanceHistory);
    final hasScoped = _prefs!.containsKey(scopedGoalKey) ||
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
    _trackingController.snapshot.addListener(_syncTodayDistanceHistory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startTrackingWithPermissionFlow());
    });
    unawaited(_initializeMovementData());
    unawaited(_loadWeight());
    unawaited(_loadHydrationData());
    _startWaterReminderLoop();
    _startHeroBannerAutoSlide();
  }

  Future<void> _startTrackingWithPermissionFlow() async {
    if (!mounted || _didRunPermissionFlow) return;
    _didRunPermissionFlow = true;

    var permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await PermissionQueue.instance.enqueue(
        () => Geolocator.requestPermission(),
      );
      if (!mounted) return;
    }

    if (permission == LocationPermission.deniedForever) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppStrings.homePermissionTitle(context)),
            content: Text(AppStrings.homePermissionContent(context)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.later(context)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Geolocator.openAppSettings();
                },
                child: Text(AppStrings.openSettings(context)),
              ),
            ],
          );
        },
      );
    }

    await _requestActivityRecognitionPermissionIfNeeded();

    if (!mounted) return;
    await _trackingController.start();
    await _trackingController.registerBackgroundTracking();
  }

  Future<void> _requestActivityRecognitionPermissionIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    var status = await Permission.activityRecognition.status;
    if (status.isGranted || status.isLimited) {
      return;
    }

    status = await PermissionQueue.instance.enqueue(
      () => Permission.activityRecognition.request(),
    );
    if (!mounted) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppStrings.homePermissionTitle(context)),
            content: Text(
              AppStrings.isEnglish(context)
                  ? 'Activity recognition permission is required to track your steps accurately.'
                  : 'Cần quyền nhận diện hoạt động để theo dõi bước chân chính xác.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.later(context)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: Text(AppStrings.openSettings(context)),
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

  Future<void> _migrateLegacyWeightIfNeeded() async {
    if (_prefs == null) return;
    if (_prefs!.getBool(_weightMigrationKey) == true) return;

    final scopedKey = _accountKey(_prefWeightKg);
    if (!_prefs!.containsKey(scopedKey) && _prefs!.containsKey(_prefWeightKg)) {
      final legacyWeight = _prefs!.getDouble(_prefWeightKg);
      if (legacyWeight != null) {
        await _prefs!.setDouble(scopedKey, legacyWeight);
      }
      await _prefs!.remove(_prefWeightKg);
    }

    await _prefs!.setBool(_weightMigrationKey, true);
  }

  Future<void> _loadWeight() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _migrateLegacyWeightIfNeeded();
    final hasCustomWaterGoal =
        _prefs?.containsKey(_accountKey(_prefWaterGoalMl)) ?? false;

    final cloudWeight = await _homeController.getLatestWeightKg();
    if (cloudWeight != null) {
      await _prefs?.setDouble(_accountKey(_prefWeightKg), cloudWeight);
    }

    if (!mounted) return;
    setState(() {
      _weightKg = _prefs?.getDouble(_accountKey(_prefWeightKg));
      if (!hasCustomWaterGoal) {
        _waterGoalMl = _recommendedGoalMl();
      }
    });
    _trackingController.setWeightKg(_weightKg);
    await _saveHydrationData();
    unawaited(_maybePromptWeightMonthlyCheck());
  }

  Future<void> _editWeight() async {
    final ctrl = TextEditingController(
      text: _weightKg == null ? '' : _weightKg!.toStringAsFixed(1),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEnglish ? 'Update weight' : 'Cập nhật cân nặng',
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: _isEnglish ? 'Enter weight (kg)' : 'Nhập cân nặng (kg)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel(context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.save(context)),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final raw = ctrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0 || value > 400) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish ? 'Invalid weight' : 'Cân nặng không hợp lệ',
          ),
        ),
      );
      return;
    }

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setDouble(_accountKey(_prefWeightKg), value);
    await _prefs?.setInt(
      _accountKey(_prefWeightLastUpdatedEpochMs),
      DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs?.setString(
      _accountKey(_prefWeightMonthlyPromptSeenMonth),
      _monthKey(DateTime.now()),
    );
    try {
      await _homeController.saveWeightKg(value);
    } catch (_) {
      // Keep local value even if cloud sync fails.
    }
    if (!mounted) return;
    setState(() => _weightKg = value);
    _trackingController.setWeightKg(value);
    await _saveHydrationData();
  }

  Future<void> _maybePromptWeightMonthlyCheck() async {
    if (!mounted) return;
    _prefs ??= await SharedPreferences.getInstance();

    final now = DateTime.now();
    final currentMonth = _monthKey(now);
    final seenMonthKey = _accountKey(_prefWeightMonthlyPromptSeenMonth);
    final lastSeenMonth = _prefs?.getString(seenMonthKey);
    if (lastSeenMonth == currentMonth) return;

    final lastUpdatedEpoch =
        _prefs?.getInt(_accountKey(_prefWeightLastUpdatedEpochMs));
    final shouldPrompt = _weightKg == null ||
        lastUpdatedEpoch == null ||
        now
                .difference(
                    DateTime.fromMillisecondsSinceEpoch(lastUpdatedEpoch))
                .inDays >=
            30;
    if (!shouldPrompt) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final updateNow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            _isEnglish ? 'Monthly weight check-in' : 'Nhắc cập nhật cân nặng',
          ),
          content: Text(
            _isEnglish
                ? 'Please update your weight this month so the app can track your health and calculate hydration accurately.'
                : 'Vui lòng cập nhật cân nặng tháng này để theo dõi sức khỏe và tính lượng nước chính xác hơn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_isEnglish ? 'Later' : 'Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_isEnglish ? 'Update now' : 'Cập nhật ngay'),
            ),
          ],
        ),
      );

      await _prefs?.setString(seenMonthKey, currentMonth);
      if (updateNow == true && mounted) {
        await _editWeight();
      }
    });
  }

  bool get _isEnglish => AppStrings.isEnglish(context);

  String _waterReminderTitle() {
    return _isEnglish ? 'Time to drink water' : 'Đến giờ uống nước rồi';
  }

  String _waterPromptBody() {
    final remaining = (_waterGoalMl - _waterIntakeMl).clamp(0, 10000);
    if (_isEnglish) {
      if (remaining >= 500) {
        return 'You still need $remaining ml today. Drink 150-200ml now.';
      }
      return 'Stay hydrated. Drink 150-200ml water.';
    }
    if (remaining >= 500) {
      return 'Bạn còn thiếu $remaining ml hôm nay. Uống 150-200ml ngay.';
    }
    return 'Uống 150-200ml nước để duy trì đủ nước.';
  }

  void _startHeroBannerAutoSlide() {
    _heroBannerTimer?.cancel();
    _heroBannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_heroBannerController.hasClients) return;
      const totalBanners = 3;
      final next = (_heroBannerIndex + 1) % totalBanners;
      _heroBannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<_HomeHeroBanner> _homeHeroBanners() {
    return [
      _HomeHeroBanner(
        label: AppStrings.overviewHealthTitle(context),
        title: _isEnglish
            ? 'Health is built day by day'
            : 'Sống khỏe bắt đầu từ hôm nay',
        subtitle: _isEnglish
            ? 'Keep your daily rhythm stable to improve sleep and energy.'
            : 'Giữ nhịp sinh hoạt ổn định để cải thiện giấc ngủ và năng lượng.',
      ),
      _HomeHeroBanner(
        label: _isEnglish ? 'DAILY FOCUS' : 'TRỌNG TÂM HÔM NAY',
        title: _isEnglish
            ? 'Great. You are on the right track'
            : 'Bạn xứng đáng với một cơ thể tốt hơn',
        subtitle: _isEnglish
            ? 'Keep your hydration and sleep stable to improve workout quality.'
            : 'Giữ ổn định nước uống và giấc ngủ để nâng chất lượng buổi tập.',
      ),
      _HomeHeroBanner(
        label: _isEnglish ? 'CONSISTENCY' : 'SỰ ĐỀU ĐẶN',
        title: _isEnglish
            ? 'Small steps create big changes'
            : 'Yêu bản thân bằng cách giữ gìn sức khỏe',
        subtitle: _isEnglish
            ? 'A 10-minute walk today is better than skipping the whole day.'
            : 'Đi bộ 10 phút hôm nay vẫn tốt hơn bỏ trống cả ngày.',
      ),
    ];
  }

  List<_ExploreWorkoutItem> _exploreWorkouts() {
    return [
      _ExploreWorkoutItem(
        label: AppStrings.trainingLabel(context),
        title: AppStrings.yogaMorningTitle(context).replaceAll('\n', ' '),
        subtitle: AppStrings.yogaMorningSubtitle(context),
        icon: Icons.self_improvement,
        youtubeUrl: 'https://www.youtube.com/watch?v=v7AYKMP6rOE',
      ),
      _ExploreWorkoutItem(
        label: _isEnglish ? 'WORKOUT' : 'LUYỆN TẬP',
        title: _isEnglish ? '12-minute cardio dance' : '12 phút cardio dance',
        subtitle: _isEnglish
            ? 'Boost your heart rate and burn calories quickly'
            : 'Tăng nhịp tim và đốt calo hiệu quả',
        icon: Icons.directions_run,
        youtubeUrl: 'https://www.youtube.com/watch?v=ml6cT4AZdqI',
      ),
      _ExploreWorkoutItem(
        label: _isEnglish ? 'HIIT' : 'HIIT',
        title: _isEnglish ? '15-minute fat burn HIIT' : '15 phút HIIT đốt mỡ',
        subtitle: _isEnglish
            ? 'Short, intense session for busy days'
            : 'Bài tập cường độ cao, phù hợp ngày bận rộn',
        icon: Icons.flash_on,
        youtubeUrl: 'https://www.youtube.com/watch?v=UBMk30rjy0o',
      ),
      _ExploreWorkoutItem(
        label: _isEnglish ? 'CORE' : 'CORE',
        title: _isEnglish ? '7-minute plank challenge' : '7 phút plank core',
        subtitle: _isEnglish
            ? 'Strengthen abs and improve posture'
            : 'Tăng sức mạnh bụng và cải thiện tư thế',
        icon: Icons.fitness_center,
        youtubeUrl: 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
      ),
      _ExploreWorkoutItem(
        label: _isEnglish ? 'RECOVERY' : 'PHỤC HỒI',
        title: _isEnglish
            ? '10-minute full body stretch'
            : '10 phút giãn cơ toàn thân',
        subtitle: _isEnglish
            ? 'Relax muscles after work or workouts'
            : 'Thư giãn cơ bắp sau làm việc hoặc tập nặng',
        icon: Icons.accessibility_new,
        youtubeUrl: 'https://www.youtube.com/watch?v=L_xrDAtykMI',
      ),
    ];
  }

  Future<void> _openExploreWorkout(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Cannot open YouTube link right now.'
                : 'Không thể mở liên kết YouTube lúc này.',
          ),
        ),
      );
    }
  }

  (int minMl, int maxMl) _recommendedWaterRangeMl() {
    final w = _weightKg;
    if (w == null || w <= 0) {
      return (1500, 2500);
    }
    final minMl = (w * 30).round().clamp(1200, 4500);
    final maxMl = (w * 35).round().clamp(minMl, 5200);
    return (minMl, maxMl);
  }

  int _recommendedGoalMl() {
    if (_weightKg == null || _weightKg! <= 0) {
      return 2000;
    }
    final (minMl, maxMl) = _recommendedWaterRangeMl();
    final fromWeight = ((minMl + maxMl) / 2).round();
    return fromWeight.clamp(1200, 5000);
  }

  Future<int?> _pickRecommendedGoalMl() async {
    final (minMl, maxMl) = _recommendedWaterRangeMl();
    if (_weightKg == null || _weightKg! <= 0 || minMl == maxMl) {
      return _recommendedGoalMl();
    }

    return showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEnglish
                      ? 'Choose recommended goal'
                      : 'Chọn mức gợi ý theo cân nặng',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(
                    _isEnglish
                        ? 'Lower target (30 ml/kg): $minMl ml/day'
                        : 'Mức thấp (30 ml/kg): $minMl ml/ngày',
                  ),
                  onTap: () => Navigator.of(context).pop(minMl),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_drink_outlined),
                  title: Text(
                    _isEnglish
                        ? 'Higher target (35 ml/kg): $maxMl ml/day'
                        : 'Mức cao (35 ml/kg): $maxMl ml/ngày',
                  ),
                  onTap: () => Navigator.of(context).pop(maxMl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _normalizeGoalMl(int value) {
    return value.clamp(1000, 5000);
  }

  int _normalizeIntakeMl(int value) {
    return value.clamp(0, 9000);
  }

  double _expectedWaterProgressAt(DateTime now) {
    final start = DateTime(now.year, now.month, now.day, 6);
    final end = DateTime(now.year, now.month, now.day, 23, 59);
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    final elapsed = now.difference(start).inMinutes;
    final total = end.difference(start).inMinutes;
    if (total <= 0) return 0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool _isWaterBehindSchedule(DateTime now) {
    if (_waterGoalMl <= 0) return false;
    final expected = _waterGoalMl * _expectedWaterProgressAt(now);
    return _waterIntakeMl + 120 < expected;
  }

  int _smartReminderIntervalMinutes(DateTime now) {
    // Formula: remaining_water / remaining_time = ml needed per hour
    // Ensures even spacing throughout the day (60-120 min, i.e., 1-2 hours)
    final remaining = (_waterGoalMl - _waterIntakeMl).clamp(0, 10000);
    if (remaining <= 0) return 180; // Too much already, check in 3 hours

    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    final minsLeft = endOfDay.difference(now).inMinutes.clamp(1, 1200);
    final hoursLeft = minsLeft / 60.0;
    final neededMlPerHour = remaining / hoursLeft;

    // Thresholds adjusted to keep intervals within 60-120 minutes (1-2 hours)
    if (neededMlPerHour >= 400) return 60; // Very behind - remind every hour
    if (neededMlPerHour >= 300) return 75; // Behind - remind every 75 min
    if (neededMlPerHour >= 200) return 90; // On pace - remind every 90 min
    return 120; // Ahead or comfortable - remind every 2 hours
  }

  Future<void> _loadHydrationData() async {
    _prefs ??= await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final savedDay = _prefs?.getString(_accountKey(_prefWaterDateKey));
    final resetNeeded = savedDay != today;
    final defaultGoal = _recommendedGoalMl();

    _waterGoalMl = _normalizeGoalMl(
      _prefs?.getInt(_accountKey(_prefWaterGoalMl)) ?? defaultGoal,
    );
    _waterIntakeMl = resetNeeded
        ? 0
        : _normalizeIntakeMl(
            _prefs?.getInt(_accountKey(_prefWaterIntakeMl)) ?? 0);
    _waterReminderEnabled =
        _prefs?.getBool(_accountKey(_prefWaterReminderEnabled)) ?? true;
    _waterManualIntervalMinutes =
        (_prefs?.getInt(_accountKey(_prefWaterManualIntervalMinutes)) ?? 90)
            .clamp(45, 180);

    final lastDrinkEpoch =
        _prefs?.getInt(_accountKey(_prefWaterLastDrinkEpochMs));
    final lastReminderEpoch =
        _prefs?.getInt(_accountKey(_prefWaterLastReminderEpochMs));

    _lastWaterDrinkAt = lastDrinkEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastDrinkEpoch);
    _lastWaterReminderAt = lastReminderEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastReminderEpoch);

    await _prefs?.setString(_accountKey(_prefWaterDateKey), today);
    await _saveHydrationData();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveHydrationData({bool syncImmediately = false}) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_accountKey(_prefWaterGoalMl), _waterGoalMl);
    await _prefs?.setInt(_accountKey(_prefWaterIntakeMl), _waterIntakeMl);
    await _prefs?.setBool(
      _accountKey(_prefWaterReminderEnabled),
      _waterReminderEnabled,
    );
    await _prefs?.setInt(
      _accountKey(_prefWaterManualIntervalMinutes),
      _waterManualIntervalMinutes,
    );
    await _prefs?.setString(
        _accountKey(_prefWaterDateKey), _dayKey(DateTime.now()));
    if (_lastWaterDrinkAt != null) {
      await _prefs?.setInt(
        _accountKey(_prefWaterLastDrinkEpochMs),
        _lastWaterDrinkAt!.millisecondsSinceEpoch,
      );
    }
    if (_lastWaterReminderAt != null) {
      await _prefs?.setInt(
        _accountKey(_prefWaterLastReminderEpochMs),
        _lastWaterReminderAt!.millisecondsSinceEpoch,
      );
    }
    if (syncImmediately) {
      await _syncDailyJournalSummary();
    } else {
      unawaited(_syncDailyJournalSummary());
    }
  }

  Future<void> _addWaterIntake(int ml) async {
    if (ml == 0) return;
    setState(() {
      _waterIntakeMl = _normalizeIntakeMl(_waterIntakeMl + ml);
      _lastWaterDrinkAt = DateTime.now();
    });
    await _saveHydrationData();
  }

  Future<void> _updateWaterGoal(
    int goalMl, {
    bool syncImmediately = false,
  }) async {
    setState(() {
      _waterGoalMl = _normalizeGoalMl(goalMl);
      _waterIntakeMl = _normalizeIntakeMl(_waterIntakeMl);
    });
    await _saveHydrationData(syncImmediately: syncImmediately);
  }

  void _startWaterReminderLoop() {
    _waterReminderTimer?.cancel();
    _waterReminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      unawaited(_checkAndSendWaterReminder());
    });
  }

  Future<void> _checkAndSendWaterReminder() async {
    _prefs ??= await SharedPreferences.getInstance();
    final notificationsEnabled =
        _prefs?.getBool(_prefNotificationsEnabled) ?? true;
    if (!notificationsEnabled || !_waterReminderEnabled) {
      return;
    }
    if (_waterIntakeMl >= _waterGoalMl) {
      return;
    }

    final now = DateTime.now();
    final smartInterval = _smartReminderIntervalMinutes(now);
    final interval = smartInterval < _waterManualIntervalMinutes
        ? smartInterval
        : _waterManualIntervalMinutes;

    final minutesSinceDrink = _lastWaterDrinkAt == null
        ? interval
        : now.difference(_lastWaterDrinkAt!).inMinutes;
    final minutesSinceReminder = _lastWaterReminderAt == null
        ? 999
        : now.difference(_lastWaterReminderAt!).inMinutes;

    final shouldRemindByTime = minutesSinceDrink >= interval;
    final shouldRemindByProgress = _isWaterBehindSchedule(now);

    if (!(shouldRemindByTime || shouldRemindByProgress)) {
      return;
    }
    if (minutesSinceReminder < 30) {
      return;
    }

    await HydrationNotificationService.instance.showHydrationReminder(
      title: _waterReminderTitle(),
      body: _waterPromptBody(),
    );

    try {
      await _backendApiService.addMyNotification(
        title: _waterReminderTitle(),
        message: _waterPromptBody(),
        isImportant: false,
      );
    } catch (e) {
      debugPrint('save hydration notification failed: $e');
    }

    _lastWaterReminderAt = now;
    await _saveHydrationData();
  }

  Future<void> _showHydrationSheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    final (minMl, maxMl) = _recommendedWaterRangeMl();
    int draftGoal = _waterGoalMl;
    int draftInterval = _waterManualIntervalMinutes;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final progress =
                (_waterGoalMl <= 0 ? 0.0 : _waterIntakeMl / _waterGoalMl)
                    .clamp(0.0, 1.0);
            final remaining = (_waterGoalMl - _waterIntakeMl).clamp(0, 10000);
            final now = DateTime.now();
            final smartMinutes = _smartReminderIntervalMinutes(now);

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight * 0.85;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 46,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _isEnglish
                                  ? 'Water intake reminder'
                                  : 'Nhắc uống nước',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isEnglish
                                  ? 'Recommended: 1.5 - 2.5L/day or 30-35 ml/kg.'
                                  : 'Mức cơ bản: 1.5 - 2.5L/ngày, hoặc 30-35 ml/kg.',
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEnglish
                                  ? 'Your recommendation: ${(minMl / 1000).toStringAsFixed(1)} - ${(maxMl / 1000).toStringAsFixed(1)} L/day.'
                                  : 'Gợi ý cho bạn: ${(minMl / 1000).toStringAsFixed(1)} - ${(maxMl / 1000).toStringAsFixed(1)} L/ngày.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEnglish
                                  ? (_weightKg == null
                                      ? 'Enter your weight for a more accurate ml/kg recommendation.'
                                      : 'Calculated from your weight: ${_weightKg!.toStringAsFixed(1)} kg.')
                                  : (_weightKg == null
                                      ? 'Hãy nhập cân nặng để tính gợi ý ml/kg chính xác hơn.'
                                      : 'Đang tính theo cân nặng: ${_weightKg!.toStringAsFixed(1)} kg.'),
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.66),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(_waterIntakeMl / 1000).toStringAsFixed(1)} / ${(_waterGoalMl / 1000).toStringAsFixed(1)} L',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 10,
                                      backgroundColor:
                                          colorScheme.outlineVariant,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    remaining <= 0
                                        ? (_isEnglish
                                            ? 'Goal completed.'
                                            : 'Bạn đã đạt mục tiêu hôm nay.')
                                        : (_isEnglish
                                            ? 'Remaining: $remaining ml'
                                            : 'Còn thiếu: $remaining ml'),
                                    style: TextStyle(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await _addWaterIntake(150);
                                    setModalState(() {});
                                  },
                                  child: const Text('+150 ml'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await _addWaterIntake(200);
                                    setModalState(() {});
                                  },
                                  child: const Text('+200 ml'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await _addWaterIntake(300);
                                    setModalState(() {});
                                  },
                                  child: const Text('+300 ml'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isEnglish
                                  ? 'Custom daily goal: $draftGoal ml'
                                  : 'Mục tiêu tự nhập: $draftGoal ml',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Slider(
                              value: draftGoal.toDouble(),
                              min: 1000,
                              max: 5000,
                              divisions: 40,
                              label: '$draftGoal ml',
                              onChanged: (value) {
                                setModalState(() {
                                  draftGoal = value.round();
                                });
                              },
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    final recommend =
                                        await _pickRecommendedGoalMl();
                                    if (recommend == null) return;
                                    setModalState(() {
                                      draftGoal = recommend;
                                    });
                                    await _updateWaterGoal(recommend);
                                  },
                                  child: Text(
                                    _isEnglish
                                        ? 'Use recommendation'
                                        : 'Dùng mức gợi ý',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    await _updateWaterGoal(
                                      draftGoal,
                                      syncImmediately: true,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isEnglish
                                              ? 'Hydration goal saved.'
                                              : 'Đã lưu mục tiêu nước.',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(AppStrings.save(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _waterReminderEnabled,
                              onChanged: (v) async {
                                setState(() {
                                  _waterReminderEnabled = v;
                                });
                                setModalState(() {});
                                await _saveHydrationData();
                              },
                              title: Text(
                                _isEnglish
                                    ? 'Hydration reminder'
                                    : 'Nhắc nhở uống nước',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                _isEnglish
                                    ? 'Smart mode adjusts reminders by remaining water and time left.'
                                    : 'Chế độ thông minh điều chỉnh tần suất theo lượng thiếu và thời gian còn lại.',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isEnglish
                                  ? 'Manual cap: every $draftInterval minutes (smart: $smartMinutes minutes).'
                                  : 'Ngưỡng tay: mỗi $draftInterval phút (thông minh đề xuất: $smartMinutes phút).',
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                            Slider(
                              value: draftInterval.toDouble(),
                              min: 45,
                              max: 180,
                              divisions: 9,
                              label: '$draftInterval min',
                              onChanged: (value) {
                                setModalState(() {
                                  draftInterval = value.round();
                                });
                              },
                              onChangeEnd: (value) async {
                                _waterManualIntervalMinutes = value.round();
                                await _saveHydrationData();
                              },
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEnglish
                                        ? 'Hydration Tips'
                                        : 'Mẹo Uống Nước',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isEnglish
                                        ? '• Drink 150-200 ml per session\n• Space drinks 1-2 hours apart\n• Sip slowly for better absorption\n• Avoid large amounts at once'
                                        : '• Uống 150-200 ml mỗi lần\n• Cách nhau 1-2 giờ một lần\n• Uống từ từ để hấp thụ tốt\n• Tránh uống quá nhiều một lúc',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onPrimaryContainer,
                                      height: 1.6,
                                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _trackingController.snapshot.removeListener(_syncTodayDistanceHistory);
    _trackingController.dispose();
    _waterReminderTimer?.cancel();
    _heroBannerTimer?.cancel();
    _heroBannerController.dispose();
    _explorePageController.dispose();
    super.dispose();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _monthKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';

  String _todayResetKey(DateTime dt) =>
      '${_accountKey(_prefTodayResetDone)}.${_dayKey(dt)}.$_manualResetVersion';

  String _shortDayLabel(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

  String _formatNumber(num value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  String _formatSleepText(int minutes) {
    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;
    return '${hours}h ${remaining}m';
  }

  List<MapEntry<DateTime, int>> _last7DaysSleep(
    List<SleepSession> sessions,
  ) {
    final now = DateTime.now();
    final byDay = <String, int>{};
    for (final session in sessions) {
      final key = _dayKey(session.end);
      byDay[key] = (byDay[key] ?? 0) + session.durationMinutes;
    }

    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      final minutes = byDay[_dayKey(day)] ?? 0;
      return MapEntry(day, minutes);
    });
  }

  Widget _buildSleepStatCell({
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _showSleepHistorySheet(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final snapshot = _trackingController.snapshot.value;
    final int totalMinutes = snapshot.sleepMinutes;
    final String sleepText = _formatSleepText(totalMinutes);
    final double progress = (totalMinutes / 480).clamp(0.0, 1.0);
    final history = _last7DaysSleep(_trackingController.sleepHistory.value);
    var selectedIndex = history.length - 1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight * 0.8;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 46,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow
                                        .withValues(alpha: 0.16),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.lastSleepSession(context),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    sleepText,
                                    style: TextStyle(
                                      fontSize: 42,
                                      height: 1.0,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    snapshot.isSleeping
                                        ? AppStrings.currentStatusSleeping(
                                            context)
                                        : AppStrings.currentStatusAwake(
                                            context),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 10,
                                      backgroundColor:
                                          colorScheme.outlineVariant,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.sleepGoalReference(context),
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              AppStrings.sleepRecentTitle(context),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.sleepGoalReference(context),
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 260),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: history.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final day = history[index].key;
                                  final minutes = history[index].value;
                                  final ratio = (minutes / 480).clamp(0.0, 1.0);
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
                                            ? colorScheme.primary.withValues(
                                                alpha: 0.12,
                                              )
                                            : colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.outlineVariant,
                                          width: isSelected ? 1.4 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                      ? colorScheme.primary
                                                      : colorScheme.onSurface,
                                                ),
                                              ),
                                              Text(
                                                _formatSleepText(minutes),
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            child: LinearProgressIndicator(
                                              value: ratio,
                                              minHeight: 8,
                                              backgroundColor:
                                                  colorScheme.outlineVariant,
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.primary
                                                      .withValues(alpha: 0.74),
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
                                final selectedMinutes =
                                    history[selectedIndex].value;
                                final selectedPercent =
                                    (selectedMinutes / 480).clamp(0.0, 1.0);

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            AppStrings.statsForDay(
                                              context,
                                              _shortDayLabel(selectedDay),
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${(selectedPercent * 100).round()}% mục tiêu',
                                              style: TextStyle(
                                                color: colorScheme.primary,
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
                                            child: _buildSleepStatCell(
                                              label: 'NGU',
                                              value: _formatSleepText(
                                                selectedMinutes,
                                              ),
                                              colorScheme: colorScheme,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildSleepStatCell(
                                              label: 'MUC TIEU',
                                              value: '8h 00m',
                                              colorScheme: colorScheme,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        height: 90,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: List.generate(
                                              history.length, (index) {
                                            final day = history[index].key;
                                            final minutes =
                                                history[index].value;
                                            final selected =
                                                index == selectedIndex;
                                            final ratio =
                                                (minutes / 480).clamp(0.0, 1.0);
                                            final barHeight =
                                                18.0 + (ratio * 52.0);
                                            return Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3),
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
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme
                                                                .outlineVariant,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
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
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                alpha: 0.72,
                                                              ),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
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
    final calories = snapshot.caloriesKcal.round();
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
    unawaited(_syncDailyJournalSummary());
  }

  Future<void> _syncDailyJournalSummary() async {
    final snapshot = _trackingController.snapshot.value;
    final today = DateTime.now();
    final waterGoal = _waterGoalMl > 0 ? _waterGoalMl : _recommendedGoalMl();
    await _journalNoteService.upsertDailySummary(
      day: today,
      steps: snapshot.steps,
      sleepMinutes: snapshot.sleepMinutes,
      waterMl: _waterIntakeMl,
      waterGoalMl: waterGoal,
      distanceKm: snapshot.distanceMeters / 1000.0,
      caloriesKcal: snapshot.caloriesKcal,
    );
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
    final colorScheme = Theme.of(context).colorScheme;
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
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight * 0.85;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 46,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.movementGoalTitle(context),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.todayStats(
                                context,
                                distanceKm.toStringAsFixed(2),
                                _formatNumber(steps),
                                _formatNumber(calories),
                              ),
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.dailyGoalLabel(
                                context,
                                draftGoal.toStringAsFixed(1),
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            Slider(
                              value: draftGoal,
                              min: 1,
                              max: 20,
                              divisions: 38,
                              label: '${draftGoal.toStringAsFixed(1)} km',
                              activeColor: colorScheme.primary,
                              onChanged: (value) {
                                setModalState(() {
                                  draftGoal = value;
                                });
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.last7DaysHistory(context),
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 260),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: history.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final day = history[index].key;
                                  final km = history[index].value;
                                  final ratio =
                                      (km / draftGoal).clamp(0.0, 1.0);
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
                                            ? colorScheme.primary.withValues(
                                                alpha: 0.12,
                                              )
                                            : colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.outlineVariant,
                                          width: isSelected ? 1.4 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                      ? colorScheme.primary
                                                      : colorScheme.onSurface,
                                                ),
                                              ),
                                              Text(
                                                '${km.toStringAsFixed(2)} km',
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            child: LinearProgressIndicator(
                                              value: ratio,
                                              minHeight: 8,
                                              backgroundColor:
                                                  colorScheme.outlineVariant,
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.primary
                                                      .withValues(alpha: 0.74),
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
                                final isToday = _dayKey(selectedDay) ==
                                    _dayKey(DateTime.now());
                                final selectedSteps = isToday
                                    ? steps
                                    : ((selectedKm * 1000) / 0.78).round();
                                final selectedCalories = isToday
                                    ? calories
                                    : (selectedKm * 55).round();
                                final selectedPercent = draftGoal <= 0
                                    ? 0
                                    : ((selectedKm / draftGoal) * 100)
                                        .clamp(0.0, 999.0)
                                        .round();

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            AppStrings.statsForDay(
                                              context,
                                              _shortDayLabel(selectedDay),
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(
                                                alpha: 0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              AppStrings.goalPercent(
                                                context,
                                                selectedPercent,
                                              ),
                                              style: TextStyle(
                                                color: colorScheme.primary,
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
                                              label: AppStrings.distanceLabel(
                                                  context),
                                              value:
                                                  selectedKm.toStringAsFixed(2),
                                              unit: 'km',
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildStatCell(
                                              label: AppStrings.stepsLabel(
                                                  context),
                                              value:
                                                  _formatNumber(selectedSteps),
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildStatCell(
                                              label: AppStrings.caloriesLabel(
                                                  context),
                                              value: _formatNumber(
                                                  selectedCalories),
                                              unit: 'kcal',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        height: 90,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children:
                                              List.generate(history.length, (
                                            index,
                                          ) {
                                            final day = history[index].key;
                                            final km = history[index].value;
                                            final selected =
                                                index == selectedIndex;
                                            final ratio = draftGoal <= 0
                                                ? 0.0
                                                : (km / draftGoal)
                                                    .clamp(0.0, 1.0);
                                            final barHeight =
                                                18.0 + (ratio * 52.0);
                                            return Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme
                                                                .outlineVariant,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10,
                                                        ),
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
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                alpha: 0.72,
                                                              ),
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
                                child: Text(
                                  AppStrings.saveGoal(context),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
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
    final staticMetrics = _homeController.getMetrics(context);
    final metrics = List<MetricItem>.from(staticMetrics);
    if (metrics.length > 1) {
      final progress = (_waterGoalMl <= 0 ? 0.0 : _waterIntakeMl / _waterGoalMl)
          .clamp(0.0, 1.0);
      final remaining = (_waterGoalMl - _waterIntakeMl).clamp(0, 10000);
      final subtitle = remaining <= 0
          ? (_isEnglish ? 'Goal completed today.' : 'Đã đạt mục tiêu hôm nay')
          : (_isEnglish
              ? '$remaining ml remaining'
              : 'Còn thiếu $remaining ml');
      metrics[1] = MetricItem(
        title: AppStrings.homeMetricWaterTitle(context),
        value: (_waterIntakeMl / 1000).toStringAsFixed(1),
        unit: '/${(_waterGoalMl / 1000).toStringAsFixed(1)}L',
        subtitle: subtitle,
        showProgress: true,
        progress: progress,
      );
    }
    if (_weightKg != null && metrics.length > 2) {
      final current = metrics[2];
      metrics[2] = MetricItem(
        title: current.title,
        value: _weightKg!.toStringAsFixed(1),
        unit: current.unit,
        subtitle: current.subtitle,
        showProgress: current.showProgress,
        progress: current.progress,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final exploreItems = _exploreWorkouts();
    final exploreGradients = <List<Color>>[
      [
        colorScheme.primary.withValues(alpha: 0.22),
        colorScheme.secondary.withValues(alpha: 0.16),
      ],
      [
        colorScheme.secondary.withValues(alpha: 0.22),
        colorScheme.primary.withValues(alpha: 0.14),
      ],
      [
        colorScheme.tertiary.withValues(alpha: 0.22),
        colorScheme.primary.withValues(alpha: 0.14),
      ],
    ];

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: AppStrings.homeTopTitle(context),
                onUserTap: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.profile);
                  await _loadWeight();
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.84),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 142,
                      child: PageView.builder(
                        controller: _heroBannerController,
                        itemCount: _homeHeroBanners().length,
                        onPageChanged: (index) {
                          setState(() {
                            _heroBannerIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final banner = _homeHeroBanners()[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banner.label,
                                style: TextStyle(
                                  color: colorScheme.onPrimary
                                      .withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                banner.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                banner.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onPrimary
                                      .withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          List.generate(_homeHeroBanners().length, (index) {
                        final active = _heroBannerIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: active
                                ? colorScheme.onPrimary
                                : colorScheme.onPrimary.withValues(alpha: 0.45),
                          ),
                        );
                      }),
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
                  final estimatedCalories = snapshot.caloriesKcal.round();
                  final sleepHours = snapshot.sleepMinutes ~/ 60;
                  final sleepRemaining = snapshot.sleepMinutes % 60;
                  final sleepText = '${sleepHours}h ${sleepRemaining}m';

                  final distanceMetric = MetricItem(
                    title: AppStrings.distanceTodayTitle(context),
                    value: distanceText,
                    unit: 'km',
                    subtitle: AppStrings.distanceSubtitle(
                      context,
                      _formatNumber(estimatedSteps),
                      _formatNumber(estimatedCalories),
                      _dailyGoalKm.toStringAsFixed(1),
                    ),
                  );

                  final sleepMetric = MetricItem(
                    title: AppStrings.sleepRecentTitle(context),
                    value: sleepText,
                    unit: '',
                    subtitle: snapshot.isSleeping
                        ? AppStrings.sleepScoringSleep(context)
                        : AppStrings.sleepScoringAwake(context),
                    showProgress: true,
                    progress: (snapshot.sleepMinutes / 480).clamp(0.0, 1.0),
                  );

                  final otherMetrics =
                      metrics.length > 1 ? metrics.sublist(1) : <MetricItem>[];
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

                      if (item.title ==
                          AppStrings.homeMetricWeightTitle(context)) {
                        _editWeight();
                        return;
                      }

                      if (item.title ==
                          AppStrings.homeMetricWaterTitle(context)) {
                        _showHydrationSheet();
                        return;
                      }

                      if (item.showProgress && index != 0) {
                        _showSleepHistorySheet(context);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.exploreMore(context),
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 214,
                child: PageView.builder(
                  controller: _explorePageController,
                  itemCount: exploreItems.length,
                  padEnds: false,
                  onPageChanged: (index) {
                    setState(() {
                      _explorePageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = exploreItems[index];
                    final gradient =
                        exploreGradients[index % exploreGradients.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _openExploreWorkout(item.youtubeUrl),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.surface,
                                  gradient[0],
                                  gradient[1],
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow
                                      .withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: colorScheme.surface.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: colorScheme.primary,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color:
                                              colorScheme.onSurface.withValues(
                                            alpha: 0.70,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 29,
                                          height: 0.98,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'YouTube',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.14),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(exploreItems.length, (index) {
                  final active = _explorePageIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: active
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreWorkoutItem {
  const _ExploreWorkoutItem({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.youtubeUrl,
  });

  final String label;
  final String title;
  final String subtitle;
  final IconData icon;
  final String youtubeUrl;
}

class _HomeHeroBanner {
  const _HomeHeroBanner({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final String label;
  final String title;
  final String subtitle;
}
