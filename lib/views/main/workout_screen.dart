import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../controllers/workout_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/workout_item.dart';
import '../../models/workout_history_item.dart';
import '../../services/journal_note_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class _DayWorkoutPlan {
  const _DayWorkoutPlan({required this.day, required this.items});

  final String day;
  final List<String> items;
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  static const _prefWeightKg = 'profile.weightKg';
  static const _prefWorkoutHistory = 'workout.history.v1';
  final AIController _aiController = AIController();
  final JournalNoteService _journalNoteService = const JournalNoteService();
  final MainNavigationController _navController = MainNavigationController();
  Timer? _weightSyncTimer;
  final WorkoutController _workoutController = WorkoutController();
  String? _aiWorkoutPlan;
  List<_DayWorkoutPlan> _weeklyPlan = const [];
  List<WorkoutHistoryItem> _history = const [];
  bool _isLoading = false;
  bool _isSavingPlan = false;
  double? _weightKg;
  int _selectedGoalIndex = 0;
  int _selectedLevelIndex = 0;
  int _sessionsPerWeek = 4;
  int _historyFilterDays = 0; // 0=all, 7, 30
  int _selectedProgramFilter = -1; // -1 = tất cả

  static const List<(String label, String prompt)> _goalOptions = [
    ('Giảm mỡ', 'Giảm mỡ và nâng cao sức bền'),
    ('Tăng cơ', 'Tăng cơ và cải thiện sức mạnh'),
    ('Tăng sức bền', 'Tăng sức bền tim mạch và độ bền toàn thân'),
    ('Duy trì', 'Duy trì sức khỏe và vận động đều đặn'),
  ];

  static const List<(String label, String prompt)> _levelOptions = [
    ('Mới bắt đầu', 'Mới bắt đầu, tập 2 buổi/tuần'),
    ('Trung cấp', 'Trung cấp, tập 3-4 buổi/tuần'),
    ('Nâng cao', 'Nâng cao, tập 5 buổi/tuần'),
  ];

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _accountKey(String base) => '$base.$_userScope';

  @override
  void initState() {
    super.initState();
    _navController.addListener(_onNavChanged);
    _loadWeight();
    _loadWorkoutHistory();
    _startWeightSync();
  }

  @override
  void dispose() {
    _weightSyncTimer?.cancel();
    _navController.removeListener(_onNavChanged);
    super.dispose();
  }

  void _onNavChanged() {
    if (_navController.index == 1) {
      _loadWeight();
    }
  }

  void _startWeightSync() {
    _weightSyncTimer?.cancel();
    _weightSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _loadWeight(onlyIfChanged: true);
    });
  }

  Future<void> _loadWeight({bool onlyIfChanged = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _accountKey(_prefWeightKg);
    if (!prefs.containsKey(scopedKey) && prefs.containsKey(_prefWeightKg)) {
      final legacyWeight = prefs.getDouble(_prefWeightKg);
      if (legacyWeight != null) {
        await prefs.setDouble(scopedKey, legacyWeight);
      }
      await prefs.remove(_prefWeightKg);
    }
    final latest = prefs.getDouble(scopedKey);
    if (!mounted) return;
    if (onlyIfChanged && latest == _weightKg) {
      return;
    }
    setState(() {
      _weightKg = latest;
    });
  }

  Future<void> _loadWorkoutHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountKey(_prefWorkoutHistory));
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _history = const []);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = <WorkoutHistoryItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final timestampMs = item['timestampMs'] is int
            ? item['timestampMs'] as int
            : int.tryParse('${item['timestampMs']}');
        // Ignore legacy/sample entries that don't have a real timestamp.
        if (timestampMs == null) continue;
        list.add(
          WorkoutHistoryItem(
            name: (item['name'] ?? '').toString(),
            date: (item['date'] ?? '').toString(),
            duration: (item['duration'] ?? '').toString(),
            kcal: (item['kcal'] ?? '').toString(),
            timestampMs: timestampMs,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _history = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _history = const []);
    }
  }

  Future<void> _persistWorkoutHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _history
        .map(
          (e) => {
            'name': e.name,
            'date': e.date,
            'duration': e.duration,
            'kcal': e.kcal,
            'timestampMs': e.timestampMs,
          },
        )
        .toList(growable: false);
    await prefs.setString(_accountKey(_prefWorkoutHistory), jsonEncode(payload));
  }

  List<WorkoutHistoryItem> _applyHistoryFilter(List<WorkoutHistoryItem> source) {
    if (_historyFilterDays == 0) return source;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final maxAgeMs = Duration(days: _historyFilterDays).inMilliseconds;
    return source.where((entry) {
      final ts = entry.timestampMs;
      if (ts == null) return false;
      return nowMs - ts <= maxAgeMs;
    }).toList(growable: false);
  }

  List<WorkoutHistoryItem> _currentWeekHistory(List<WorkoutHistoryItem> source) {
    final now = DateTime.now();
    final weekdayOffset = now.weekday - DateTime.monday;
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekdayOffset));
    final weekStartMs = weekStart.millisecondsSinceEpoch;
    return source.where((entry) {
      final ts = entry.timestampMs;
      if (ts == null) return false;
      return ts >= weekStartMs;
    }).toList(growable: false);
  }

  Future<void> _deleteHistoryAt(int indexInFiltered, List<WorkoutHistoryItem> filtered) async {
    if (indexInFiltered < 0 || indexInFiltered >= filtered.length) return;
    final target = filtered[indexInFiltered];
    final idx = _history.indexWhere((e) =>
        e.name == target.name &&
        e.date == target.date &&
        e.duration == target.duration &&
        e.kcal == target.kcal &&
        e.timestampMs == target.timestampMs);
    if (idx < 0) return;
    setState(() {
      _history = List<WorkoutHistoryItem>.from(_history)..removeAt(idx);
    });
    await _persistWorkoutHistory();
  }

  Future<void> _confirmDeleteHistoryAt(
    int indexInFiltered,
    List<WorkoutHistoryItem> filtered,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục lịch sử'),
        content: const Text('Bạn có chắc muốn xóa mục lịch sử buổi tập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _deleteHistoryAt(indexInFiltered, filtered);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa mục lịch sử.')),
    );
  }

  Future<void> _confirmClearAllHistory() async {
    if (_history.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử tập luyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _history = const [];
    });
    await _persistWorkoutHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa toàn bộ lịch sử tập luyện.')),
    );
  }

  int _estimateCalories(String workoutName, int durationMin) {
    final weight = _weightKg ?? 65.0;
    final key = workoutName.toLowerCase();
    double met = 6.0;
    if (key.contains('run') || key.contains('chạy')) {
      met = 8.0;
    } else if (key.contains('gym')) {
      met = 6.0;
    } else if (key.contains('yoga')) {
      met = 3.2;
    } else if (key.contains('cycling') || key.contains('đạp')) {
      met = 7.0;
    }
    final kcal = met * 3.5 * weight / 200 * durationMin;
    return kcal.round();
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _logWorkoutSession(WorkoutItem item) async {
    int draftDuration = 30;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final estimated = _estimateCalories(item.title, draftDuration);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi nhận buổi tập: ${item.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Thời lượng: $draftDuration phút'),
                    Slider(
                      value: draftDuration.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 22,
                      label: '$draftDuration phút',
                      onChanged: (value) {
                        setModalState(() => draftDuration = value.round());
                      },
                    ),
                    Text('Calories ước tính: $estimated kcal'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final entry = WorkoutHistoryItem(
                            name: item.title,
                            date: _todayLabel(),
                            duration: '$draftDuration phút',
                            kcal: '$estimated',
                            timestampMs: DateTime.now().millisecondsSinceEpoch,
                          );
                          if (!mounted) return;
                          setState(() {
                            _history = [entry, ..._history].take(50).toList();
                          });
                          await _persistWorkoutHistory();
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu buổi tập vào lịch sử.')),
                          );
                        },
                        child: const Text('Lưu buổi tập'),
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

  Future<void> _getAIWorkout() async {
    await _loadWeight(onlyIfChanged: true);
    setState(() => _isLoading = true);
    final selectedGoal = _goalOptions[_selectedGoalIndex].$2;
    final selectedLevel = _levelOptions[_selectedLevelIndex].$2;

    final plan = await _aiController.getPersonalizedWorkout(
      selectedGoal,
      selectedLevel,
      weightKg: _weightKg,
    );
    setState(() {
      _aiWorkoutPlan = plan;
      _weeklyPlan = _buildWeeklyPlan(plan);
      _isLoading = false;
    });
  }

  List<String> _extractExercises(String raw) {
    final lines = raw.split('\n');
    final extracted = <String>[];
    final numbered = RegExp(r'^\s*\d+\.\s*(.+)$');
    for (final line in lines) {
      final match = numbered.firstMatch(line);
      if (match == null) continue;
      final text = (match.group(1) ?? '').trim();
      if (text.isNotEmpty) {
        extracted.add(text);
      }
    }
    if (extracted.isNotEmpty) {
      return extracted;
    }

    // Fallback when response is free text without numbering.
    for (final line in lines) {
      final text = line.trim();
      if (text.isEmpty) continue;
      if (text.length < 4) continue;
      if (text.toLowerCase().startsWith('nguon:')) continue;
      if (text.toLowerCase().startsWith('lich de xuat:')) continue;
      extracted.add(text);
      if (extracted.length >= 8) break;
    }
    return extracted;
  }

  String _translateExerciseName(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('squat bodyweight')) {
      return 'Squat với trọng lượng cơ thể';
    }
    if (lower.contains('push-up')) {
      return 'Hít đất';
    }
    if (lower.contains('plank')) {
      return 'Plank (giữ thân người)';
    }
    if (lower.contains('dumbbell row')) {
      return 'Kéo tạ đơn (Dumbbell Row)';
    }
    if (lower.contains('row dây')) {
      return 'Kéo cáp (Row dây)';
    }
    if (lower.contains('glute bridge')) {
      return 'Nâng hông (Glute Bridge)';
    }
    if (lower.contains('cycling')) {
      return 'Đạp xe';
    }
    if (lower.contains('walking')) {
      return 'Đi bộ';
    }
    if (lower.contains('running') || lower.contains('run')) {
      return 'Chạy bộ';
    }
    if (lower.contains('yoga')) {
      return 'Yoga';
    }
    return input;
  }

  String _translateCategory(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('legs')) return 'Chân';
    if (lower.contains('chest')) return 'Ngực';
    if (lower.contains('back')) return 'Lưng';
    if (lower.contains('core')) return 'Cơ trung tâm';
    if (lower.contains('shoulder')) return 'Vai';
    if (lower.contains('arms')) return 'Tay';
    return input;
  }

  String _translateExerciseLine(String raw) {
    var text = raw.trim();
    // Strong translation fallback for API text variants.
    final replacements = <String, String>{
      'Squat bodyweight': 'Squat với trọng lượng cơ thể',
      'Push-up': 'Hít đất',
      'Push up': 'Hít đất',
      'Plank': 'Plank (giữ thân người)',
      'Dumbbell Row': 'Kéo tạ đơn',
      'Row dây': 'Kéo cáp',
      'Glute Bridge': 'Nâng hông',
      'Lower body': 'Thân dưới',
      'Legs': 'Chân',
      'Chest': 'Ngực',
      'Back': 'Lưng',
      'Core': 'Cơ trung tâm',
      'reps': 'lần',
    };
    replacements.forEach((k, v) {
      text = text.replaceAll(k, v);
    });

    final match = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(text);
    if (match != null) {
      final name = (match.group(1) ?? '').trim();
      final category = (match.group(2) ?? '').trim();
      final viName = _translateExerciseName(name);
      final viCategory = _translateCategory(category);
      return '$viName ($viCategory)';
    }
    return _translateExerciseName(text);
  }

  String _viLevelLabel(String input) {
    final lower = input.toLowerCase().trim();
    if (lower == 'beginner') return 'Mới bắt đầu';
    if (lower == 'intermediate') return 'Trung cấp';
    if (lower == 'advanced') return 'Nâng cao';
    return input;
  }

  String _viDayLabel(String input) {
    final lower = input.toLowerCase().trim();
    if (lower == 'thu 2') return 'Thứ 2';
    if (lower == 'thu 3') return 'Thứ 3';
    if (lower == 'thu 4') return 'Thứ 4';
    if (lower == 'thu 5') return 'Thứ 5';
    if (lower == 'thu 6') return 'Thứ 6';
    if (lower == 'thu 7') return 'Thứ 7';
    if (lower == 'chu nhat') return 'Chủ nhật';
    return input;
  }

  String _translatePlanItemText(String input) {
    var text = input;
    final replacements = <Pattern, String>{
      RegExp(r'squat bodyweight', caseSensitive: false):
          'Squat với trọng lượng cơ thể',
      RegExp(r'push\s*-?\s*up', caseSensitive: false): 'Hít đất',
      RegExp(r'plank', caseSensitive: false): 'Plank (giữ thân người)',
      RegExp(r'dumbbell row', caseSensitive: false): 'Kéo tạ đơn',
      RegExp(r'glute bridge', caseSensitive: false): 'Nâng hông',
      RegExp(r'lower body', caseSensitive: false): 'Thân dưới',
      RegExp(r'legs', caseSensitive: false): 'Chân',
      RegExp(r'chest', caseSensitive: false): 'Ngực',
      RegExp(r'back', caseSensitive: false): 'Lưng',
      RegExp(r'core', caseSensitive: false): 'Cơ trung tâm',
      RegExp(r'\breps\b', caseSensitive: false): 'lần',
      RegExp(r'\bhiep\b', caseSensitive: false): 'hiệp',
      RegExp(r'\bnghi chu dong\b', caseSensitive: false): 'Nghỉ chủ động',
      RegExp(r'\bdi bo nhe\b', caseSensitive: false): 'đi bộ nhẹ',
      RegExp(r'\bgian co\b', caseSensitive: false): 'giãn cơ',
    };
    replacements.forEach((pattern, replacement) {
      text = text.replaceAll(pattern, replacement);
    });
    return text;
  }

  String _translateRawPlanText(String raw) {
    final lines = raw.split('\n');
    final translated = <String>[];
    final levelLine = RegExp(r'^\s*Trình độ\s*:\s*(.+)\s*$', caseSensitive: false);
    for (final line in lines) {
      final m = levelLine.firstMatch(line);
      if (m != null) {
        final level = (m.group(1) ?? '').trim();
        translated.add('Trình độ: ${_viLevelLabel(level)}');
        continue;
      }
      translated.add(_translatePlanItemText(line));
    }
    return translated.join('\n');
  }

  String _workPrescription({required bool firstExercise}) {
    final goal = _goalOptions[_selectedGoalIndex].$1.toLowerCase();
    final level = _levelOptions[_selectedLevelIndex].$1.toLowerCase();

    final isBeginner = level.contains('mới bắt đầu');
    final isAdvanced = level.contains('nâng cao');

    if (goal.contains('giảm mỡ')) {
      if (isAdvanced) return firstExercise ? '4 hiệp x 12-15 lần' : '4 hiệp x 10-12 lần';
      if (isBeginner) return firstExercise ? '3 hiệp x 10-12 lần' : '3 hiệp x 8-10 lần';
      return firstExercise ? '4 hiệp x 10-12 lần' : '3 hiệp x 10-12 lần';
    }

    if (goal.contains('tăng cơ')) {
      if (isAdvanced) return firstExercise ? '5 hiệp x 6-8 lần' : '4 hiệp x 8-10 lần';
      if (isBeginner) return firstExercise ? '3 hiệp x 8-10 lần' : '3 hiệp x 10-12 lần';
      return firstExercise ? '4 hiệp x 8-10 lần' : '4 hiệp x 10-12 lần';
    }

    if (goal.contains('sức bền')) {
      if (isAdvanced) return firstExercise ? '4 hiệp x 15-20 lần' : '4 hiệp x 12-15 lần';
      if (isBeginner) return firstExercise ? '3 hiệp x 12-15 lần' : '3 hiệp x 10-12 lần';
      return firstExercise ? '4 hiệp x 12-15 lần' : '3 hiệp x 12-15 lần';
    }

    if (isAdvanced) return firstExercise ? '4 hiệp x 10-12 lần' : '4 hiệp x 8-10 lần';
    if (isBeginner) return firstExercise ? '3 hiệp x 8-10 lần' : '3 hiệp x 8-10 lần';
    return firstExercise ? '4 hiệp x 8-10 lần' : '3 hiệp x 10-12 lần';
  }

  String _dayFocusLabel(int index) {
    final goal = _goalOptions[_selectedGoalIndex].$1.toLowerCase();
    if (goal.contains('giảm mỡ')) {
      const labels = [
        'Đốt mỡ toàn thân',
        'Sức bền + nhịp tim',
        'Core + chân',
        'Đốt mỡ tăng tốc',
      ];
      return labels[index % labels.length];
    }
    if (goal.contains('tăng cơ')) {
      const labels = [
        'Push (Ngực - Vai - Tay sau)',
        'Pull (Lưng - Tay trước)',
        'Chân + Mông',
        'Sức mạnh tổng hợp',
      ];
      return labels[index % labels.length];
    }
    if (goal.contains('sức bền')) {
      const labels = [
        'Cardio nền',
        'Sức bền cơ bắp',
        'Core ổn định',
        'Cardio biến tốc',
      ];
      return labels[index % labels.length];
    }
    const labels = [
      'Duy trì thể lực',
      'Sức mạnh cơ bản',
      'Độ linh hoạt',
      'Vận động toàn thân',
    ];
    return labels[index % labels.length];
  }

  List<_DayWorkoutPlan> _buildWeeklyPlan(String raw) {
    final exercises = _extractExercises(raw);
    final days = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    if (exercises.isEmpty) {
      return days
          .map(
            (day) => _DayWorkoutPlan(
              day: day,
              items: const ['Khởi động 10 phút và đi bộ nhẹ 20 phút.'],
            ),
          )
          .toList(growable: false);
    }

    final sessionSlots = <int>{};
    if (_sessionsPerWeek >= 6) {
      sessionSlots.addAll(const [0, 1, 2, 4, 5, 6]);
    } else if (_sessionsPerWeek == 5) {
      sessionSlots.addAll(const [0, 1, 3, 4, 6]);
    } else if (_sessionsPerWeek == 4) {
      sessionSlots.addAll(const [0, 2, 4, 6]);
    } else {
      sessionSlots.addAll(const [0, 3, 5]);
    }

    return List<_DayWorkoutPlan>.generate(days.length, (index) {
      if (!sessionSlots.contains(index)) {
        return _DayWorkoutPlan(
          day: days[index],
          items: const ['Nghỉ chủ động: đi bộ nhẹ và giãn cơ 15 phút.'],
        );
      }
      final base = exercises[index % exercises.length];
      final second = exercises[(index + 1) % exercises.length];
      final baseVi = _translateExerciseLine(base);
      final secondVi = _translateExerciseLine(second);
      final firstPrescription = _workPrescription(firstExercise: true);
      final secondPrescription = _workPrescription(firstExercise: false);
      final focus = _dayFocusLabel(index);
      return _DayWorkoutPlan(
        day: days[index],
        items: [
          'Trọng tâm: $focus',
          '$baseVi - $firstPrescription',
          '$secondVi - $secondPrescription',
        ],
      );
    });
  }

  Future<void> _saveWeeklyPlanToJournal() async {
    if (_weeklyPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy tạo kế hoạch trước khi lưu.')),
      );
      return;
    }

    setState(() => _isSavingPlan = true);
    try {
      final goal = _goalOptions[_selectedGoalIndex].$1;
      final level = _levelOptions[_selectedLevelIndex].$1;
      final buffer = StringBuffer()
        ..writeln('Kế hoạch tập tuần')
        ..writeln('Mục tiêu: $goal')
        ..writeln('Trình độ: $level')
        ..writeln('Số buổi/tuần: $_sessionsPerWeek')
        ..writeln(_weightKg == null
          ? 'Cân nặng: chưa cập nhật'
          : 'Cân nặng: ${_weightKg!.toStringAsFixed(1)} kg')
        ..writeln('');

      for (final day in _weeklyPlan) {
        buffer.writeln('${day.day}:');
        for (final item in day.items) {
          buffer.writeln('- $item');
        }
      }

      await _journalNoteService.saveEntry(
        note: buffer.toString(),
        scheduledAt: DateTime.now(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu kế hoạch vào Nhật ký.')),
      );
      MainNavigationController().setIndex(4);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu kế hoạch.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPlan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final programs = _workoutController.getPrograms(context);
    final history = _history;
    final filteredHistory = _applyHistoryFilter(history);
    final weekHistory = _currentWeekHistory(history);
    final weekSessions = weekHistory.length;
    final weekKcal = weekHistory.fold<int>(
      0,
      (sum, e) => sum + (int.tryParse(e.kcal) ?? 0),
    );
    final List<WorkoutItem> shownPrograms = _selectedProgramFilter == -1
      ? programs
      : <WorkoutItem>[programs[_selectedProgramFilter]];
    final colorScheme = Theme.of(context).colorScheme;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: AppStrings.workoutScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 10),
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
                    Text(
                      AppStrings.weekGoalTitle(context),
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$weekSessions/5 Buổi tập',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '$weekKcal kcal đã đốt',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Workout Suggestion Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.aiWorkoutSuggestionTitle(context),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _weightKg == null
                          ? 'Chưa cập nhật cân nặng. Gợi ý sẽ ở mức chung.'
                          : 'Cân nặng hiện tại: ${_weightKg!.toStringAsFixed(1)} kg (gợi ý theo cân nặng).',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mục tiêu tập luyện',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_goalOptions.length, (index) {
                        final selected = _selectedGoalIndex == index;
                        return ChoiceChip(
                          label: Text(_goalOptions[index].$1),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedGoalIndex = index;
                              _aiWorkoutPlan = null;
                              _weeklyPlan = const [];
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Trình độ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_levelOptions.length, (index) {
                        final selected = _selectedLevelIndex == index;
                        return ChoiceChip(
                          label: Text(_viLevelLabel(_levelOptions[index].$1)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedLevelIndex = index;
                              _aiWorkoutPlan = null;
                              _weeklyPlan = const [];
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Số buổi/tuần: $_sessionsPerWeek',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<int>(
                          value: _sessionsPerWeek,
                          items: const [3, 4, 5]
                              .map(
                                (v) => DropdownMenuItem<int>(
                                  value: v,
                                  child: Text('$v buổi'),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _sessionsPerWeek = value;
                              if (_aiWorkoutPlan != null) {
                                _weeklyPlan = _buildWeeklyPlan(_aiWorkoutPlan!);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_weeklyPlan.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kế hoạch theo ngày',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._weeklyPlan.map(
                            (dayPlan) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _viDayLabel(dayPlan.day),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...dayPlan.items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('- ${_translatePlanItemText(item)}'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_aiWorkoutPlan != null)
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('Chi tiết API'),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(_translateRawPlanText(_aiWorkoutPlan!)),
                                ),
                              ],
                            ),
                        ],
                      )
                    else
                      Text(AppStrings.aiWorkoutSuggestionHint(context)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _getAIWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppStrings.aiGeneratePlanButton(context)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSavingPlan ? null : _saveWeeklyPlanToJournal,
                        icon: _isSavingPlan
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Lưu kế hoạch vào Nhật ký'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.programModesTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedProgramFilter == -1,
                    onSelected: (_) {
                      setState(() => _selectedProgramFilter = -1);
                    },
                  ),
                  ...List.generate(programs.length, (index) {
                    final selected = _selectedProgramFilter == index;
                    return ChoiceChip(
                      label: Text(programs[index].title),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedProgramFilter = index);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: shownPrograms.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (_, index) => InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _logWorkoutSession(shownPrograms[index]),
                  child: WorkoutCard(item: shownPrograms[index]),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.workoutHistoryTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _historyFilterDays == 0,
                    onSelected: (_) => setState(() => _historyFilterDays = 0),
                  ),
                  ChoiceChip(
                    label: const Text('7 ngày'),
                    selected: _historyFilterDays == 7,
                    onSelected: (_) => setState(() => _historyFilterDays = 7),
                  ),
                  ChoiceChip(
                    label: const Text('30 ngày'),
                    selected: _historyFilterDays == 30,
                    onSelected: (_) => setState(() => _historyFilterDays = 30),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _history.isEmpty ? null : _confirmClearAllHistory,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Xóa toàn bộ'),
                ),
              ),
              const SizedBox(height: 8),
              if (filteredHistory.isEmpty)
                Text(
                  'Chưa có dữ liệu cho bộ lọc này.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ...filteredHistory.asMap().entries.map(
                (pair) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HistoryTile(
                    item: pair.value,
                    onDelete: _history.isEmpty
                        ? null
                        : () => _confirmDeleteHistoryAt(pair.key, filteredHistory),
                  ),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
