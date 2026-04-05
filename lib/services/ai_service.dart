import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../models/food_recognition_result.dart';
import 'food_data_service.dart';

class AIService {
  // Priority: .env -> --dart-define
  static const String _apiKeyFromDefine = String.fromEnvironment(
    'GEMINI_API_KEY',
  );
  final FoodDataService _foodDataService = FoodDataService();

  // Sử dụng Gemini cho Vision + Text
  late final GenerativeModel? _model = _buildModel();

  AIService();

  String get _apiKey {
    final fromEnv = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (fromEnv.isNotEmpty) return fromEnv;
    return _apiKeyFromDefine.trim();
  }

  bool get isAiConfigured => _apiKey.isNotEmpty;

  GenerativeModel? _buildModel() {
    if (_apiKey.trim().isEmpty) {
      return null;
    }
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  GenerativeModel _requireModel() {
    final model = _model;
    if (model == null) {
      throw StateError(
          'GEMINI_API_KEY is missing. Set --dart-define=GEMINI_API_KEY=...');
    }
    return model;
  }

  String _toFriendlyAiError(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('reported as leaked') ||
        raw.contains('api key') && raw.contains('leaked')) {
      return 'API key AI da bi thu hoi do lo thong tin. Vui long cap nhat key moi.';
    }
    if (raw.contains('invalid') && raw.contains('api key')) {
      return 'API key AI khong hop le. Vui long kiem tra lai cau hinh key.';
    }
    if (raw.contains('expired') && raw.contains('api key')) {
      return 'API key AI da het han. Vui long cap nhat GEMINI_API_KEY moi.';
    }
    if (raw.contains('quota exceeded') || raw.contains('rate limit')) {
      return 'Da vuot qua han muc AI hien tai. Vui long doi hoac nang cap goi AI/Gemini.';
    }
    if (raw.contains('missing') && raw.contains('gemini_api_key')) {
      return 'Chua cau hinh GEMINI_API_KEY trong assets/env/.env (hoac --dart-define).';
    }

    return 'Khong the ket noi dich vu AI luc nay. Vui long thu lai sau.';
  }

  /// 1. Nhận diện đồ ăn hoàn toàn bằng API
  Future<FoodRecognitionResult?> recognizeFood(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      debugPrint('--- BẮT ĐẦU NHẬN DIỆN MÓN ĂN QUA API ---');
      final model = _requireModel();

      final content = [
        Content.multi([
          TextPart(
              'Phân tích hình ảnh món ăn và chỉ trả về một JSON hợp lệ, không thêm markdown hay giải thích. '
              'Định dạng bắt buộc: '
              '{"name_en": "Common English Name", "name_vi": "Tên tiếng Việt chính xác", "calories_est": 0.0, "description_vi": "Mô tả ngắn bằng tiếng Việt (2-3 câu)", "description": "Short description in English (optional)"}. '
              'Yêu cầu: name_en là tên phổ biến bằng tiếng Anh; name_vi và description_vi phải là tiếng Việt tự nhiên; '
              'description_vi tối đa 2-3 câu; calories_est là số dương.'),
          DataPart(mimeType, imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null) {
        debugPrint('Gemini Response: $text');

        // Làm sạch chuỗi JSON
        String jsonStr =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        if (jsonStr.contains('{') && jsonStr.contains('}')) {
          jsonStr = jsonStr.substring(
              jsonStr.indexOf('{'), jsonStr.lastIndexOf('}') + 1);
        }

        final Map<String, dynamic> aiData = jsonDecode(jsonStr);
        String nameEn = aiData['name_en'] ?? '';
        String nameVi = aiData['name_vi'] ?? 'Món ăn lạ';
        double calEst = (aiData['calories_est'] ?? 0).toDouble();
        String desc = aiData['description_vi'] ?? aiData['description'] ?? '';

        // Bước 2: Truy vấn USDA để lấy dữ liệu dinh dưỡng chuẩn xác nhất dựa trên tên tiếng Anh
        try {
          final usdaResult = await _foodDataService.searchUSDA(nameEn);
          if (usdaResult != null && usdaResult.calories > 0) {
            return FoodRecognitionResult(
              name: nameVi,
              calories: usdaResult.calories,
              protein: usdaResult.protein,
              fat: usdaResult.fat,
              carbs: usdaResult.carbs,
              description: desc,
              source: 'AI + USDA (Chính xác)',
            );
          }
        } catch (e) {
          debugPrint('USDA query failed, using AI estimate: $e');
        }

        // Fallback: Dùng dữ liệu ước tính từ AI
        return FoodRecognitionResult(
          name: nameVi,
          calories: calEst,
          description: desc,
          source: 'Gemini AI (Ước tính)',
        );
      }
    } catch (e) {
      debugPrint('Loi AI Service: ${_toFriendlyAiError(e)} | raw: $e');
    }
    return null;
  }

  /// 2. Gợi ý tập luyện
  Future<String> getWorkoutSuggestions(
    String goal,
    String status, {
    double? weightKg,
  }) async {
    final geminiPlan = await _getWorkoutSuggestionsFromGemini(
      goal: goal,
      status: status,
      weightKg: weightKg,
    );
    if (geminiPlan != null) {
      return geminiPlan;
    }

    final freePlan = await _getWorkoutSuggestionsFromFreeApi(
      goal: goal,
      status: status,
      weightKg: weightKg,
    );
    if (freePlan != null) {
      return freePlan;
    }
    return _localFallbackWorkoutPlan(
        goal: goal, status: status, weightKg: weightKg);
  }

  Future<String?> _getWorkoutSuggestionsFromGemini({
    required String goal,
    required String status,
    double? weightKg,
  }) async {
    if (!isAiConfigured) return null;
    try {
      final model = _requireModel();
      final prompt = '''
Tạo kế hoạch tập luyện tuần bằng tiếng Việt.
Mục tiêu: $goal
Trình độ: $status
Cân nặng: ${weightKg?.toStringAsFixed(1) ?? 'chưa cập nhật'} kg

Yêu cầu định dạng:
- Trả về text thuần, không markdown.
- Có các dòng đầu:
Nguồn: Gemini API
Mục tiêu: ...
Trình độ: ...
Cân nặng: ...

- Sau đó tạo phần "Bài tập gợi ý:" gồm đúng 6 dòng được đánh số:
1. ...
2. ...
...
6. ...

- Mỗi dòng là một bài tập cụ thể, không trùng nhau, có thể kèm nhóm cơ trong ngoặc.
- Kết thúc bằng dòng: Lịch đề xuất: 3-5 buổi/tuần, 35-60 phút/buổi.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();
      if (text.isEmpty) return null;

      final numbered = RegExp(r'^\s*\d+\.\s+', multiLine: true);
      if (!numbered.hasMatch(text)) {
        return null;
      }
      return text;
    } catch (e) {
      debugPrint('Gemini workout API error: $e');
      return null;
    }
  }

  Future<String?> _getWorkoutSuggestionsFromFreeApi({
    required String goal,
    required String status,
    double? weightKg,
  }) async {
    try {
      final uri = Uri.parse(
        'https://wger.de/api/v2/exerciseinfo/?language=2&limit=50',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final raws = (decoded['results'] as List?) ?? const [];
      if (raws.isEmpty) {
        return null;
      }

      final exercises = <Map<String, String>>[];
      for (final item in raws) {
        if (item is! Map) continue;
        final name = (item['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final category = (item['category'] is Map)
            ? ((item['category'] as Map)['name'] ?? '').toString().trim()
            : '';
        final description = _stripHtml((item['description'] ?? '').toString());
        exercises.add({
          'name': name,
          'category': category,
          'description': description,
        });
      }

      if (exercises.isEmpty) return null;

      final selected = _pickExercisesByProfile(
        exercises,
        goal: goal,
        status: status,
        weightKg: weightKg,
      );
      final buffer = StringBuffer();
      buffer.writeln(
        'Nguồn: Wger API (free) - Gợi ý theo cân nặng ${weightKg?.toStringAsFixed(1) ?? 'chưa có'} kg',
      );
      buffer.writeln('Mục tiêu: $goal');
      buffer.writeln('Trình độ: $status');
      buffer.writeln('Nhóm ưu tiên: ${_goalPriorityLabel(goal)}');
      buffer.writeln('');
      buffer.writeln('Bài tập gợi ý:');

      for (var i = 0; i < selected.length; i++) {
        final ex = selected[i];
        final name = _toViExerciseName(ex['name'] ?? 'Bài tập');
        final category = _toViCategory(ex['category'] ?? 'Tổng quát');
        const shortDesc =
            'Thực hiện đúng kỹ thuật, tăng dần khối lượng theo khả năng.';
        buffer.writeln('${i + 1}. $name ($category)');
        buffer.writeln('   - $shortDesc');
      }

      buffer.writeln('');
      buffer.writeln('Lịch đề xuất: 3-4 buổi/tuần, 35-50 phút/buổi.');
      return buffer.toString();
    } catch (e) {
      debugPrint('Free workout API error: $e');
      return null;
    }
  }

  List<Map<String, String>> _pickExercisesByProfile(
    List<Map<String, String>> exercises, {
    required String goal,
    required String status,
    double? weightKg,
  }) {
    final goalLower = goal.toLowerCase();
    final statusLower = status.toLowerCase();

    final wantsFatLoss =
        goalLower.contains('giảm mỡ') || goalLower.contains('fat');
    final wantsMuscle =
        goalLower.contains('tăng cơ') || goalLower.contains('muscle');
    final wantsEndurance =
        goalLower.contains('sức bền') || goalLower.contains('endurance');

    final beginner =
        statusLower.contains('mới bắt đầu') || statusLower.contains('beginner');
    final advanced =
        statusLower.contains('nâng cao') || statusLower.contains('advanced');

    final profileSeed = ('$goalLower|$statusLower|${weightKg?.round() ?? 0}')
        .runes
        .fold<int>(17, (acc, ch) => (acc * 31 + ch) & 0x7fffffff);

    bool cardio(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('cycling') ||
          text.contains('walking') ||
          text.contains('running') ||
          text.contains('cardio') ||
          text.contains('jump') ||
          text.contains('aerobic');
    }

    bool push(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('chest') ||
          text.contains('tricep') ||
          text.contains('shoulder') ||
          text.contains('push') ||
          text.contains('press');
    }

    bool pull(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('back') ||
          text.contains('bicep') ||
          text.contains('row') ||
          text.contains('pull');
    }

    bool legs(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('leg') ||
          text.contains('glute') ||
          text.contains('squat') ||
          text.contains('lunge') ||
          text.contains('hamstring');
    }

    bool core(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('core') ||
          text.contains('abs') ||
          text.contains('plank') ||
          text.contains('crunch');
    }

    bool mobility(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('stretch') ||
          text.contains('mobility') ||
          text.contains('yoga');
    }

    bool heavyOrComplex(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('barbell') ||
          text.contains('clean') ||
          text.contains('snatch') ||
          text.contains('weighted') ||
          text.contains('deadlift');
    }

    bool lowImpact(Map<String, String> e) {
      final text = ('${e['name']} ${e['category']}').toLowerCase();
      return text.contains('walking') ||
          text.contains('cycling') ||
          text.contains('yoga') ||
          text.contains('mobility') ||
          text.contains('stretch');
    }

    double score(Map<String, String> e) {
      var s = 0.0;
      final deterministicNoise =
          (((('${e['name']}|${e['category']}').hashCode ^ profileSeed) & 255) /
              2550.0);
      s += deterministicNoise;

      if (wantsFatLoss) {
        if (cardio(e)) s += 3.3;
        if (core(e)) s += 1.4;
        if (legs(e)) s += 1.2;
        if (push(e) || pull(e)) s += 0.6;
      } else if (wantsMuscle) {
        if (push(e)) s += 2.9;
        if (pull(e)) s += 2.6;
        if (legs(e)) s += 2.5;
        if (core(e)) s += 1.0;
        if (cardio(e)) s -= 0.3;
      } else if (wantsEndurance) {
        if (cardio(e)) s += 3.4;
        if (mobility(e)) s += 2.2;
        if (core(e)) s += 1.2;
        if (push(e) || pull(e) || legs(e)) s += 0.5;
      } else {
        if (push(e)) s += 1.5;
        if (pull(e)) s += 1.3;
        if (legs(e)) s += 1.4;
        if (core(e)) s += 1.1;
        if (cardio(e)) s += 1.0;
      }

      if (beginner) {
        if (heavyOrComplex(e)) s -= 1.6;
        if (lowImpact(e) || core(e)) s += 0.6;
      }
      if (advanced) {
        if (heavyOrComplex(e)) s += 1.1;
      }

      if (weightKg != null && weightKg >= 85) {
        if (lowImpact(e)) s += 0.8;
        if (heavyOrComplex(e) && !core(e)) s -= 0.8;
      }

      return s;
    }

    final ranked = List<Map<String, String>>.from(exercises)
      ..sort((a, b) => score(b).compareTo(score(a)));

    final used = <String>{};

    List<Map<String, String>> takeWhere(
      bool Function(Map<String, String>) predicate,
      int count,
    ) {
      final picked = <Map<String, String>>[];
      for (final exercise in ranked) {
        final key = '${exercise['name']}|${exercise['category']}';
        if (used.contains(key)) continue;
        if (!predicate(exercise)) continue;
        used.add(key);
        picked.add(exercise);
        if (picked.length >= count) break;
      }
      return picked;
    }

    final result = <Map<String, String>>[];

    if (wantsFatLoss) {
      result.addAll(
          takeWhere(cardio, weightKg != null && weightKg >= 85 ? 2 : 3));
      result.addAll(takeWhere(core, 1));
      result.addAll(takeWhere(legs, 1));
      result.addAll(takeWhere(mobility, 1));
      result.addAll(takeWhere(push, 1));
    } else if (wantsMuscle) {
      result.addAll(takeWhere(push, 2));
      result.addAll(takeWhere(pull, 2));
      result.addAll(takeWhere(legs, 1));
      result.addAll(takeWhere(core, 1));
    } else if (wantsEndurance) {
      result.addAll(takeWhere(cardio, 3));
      result.addAll(takeWhere(mobility, 2));
      result.addAll(takeWhere(core, 1));
    } else {
      result.addAll(takeWhere(legs, 2));
      result.addAll(takeWhere(push, 1));
      result.addAll(takeWhere(pull, 1));
      result.addAll(takeWhere(core, 1));
      result.addAll(takeWhere(cardio, 1));
    }

    if (result.length < 6) {
      for (final exercise in ranked) {
        final key = '${exercise['name']}|${exercise['category']}';
        if (!used.add(key)) continue;
        result.add(exercise);
        if (result.length >= 6) break;
      }
    }

    return result.take(6).toList(growable: false);
  }

  String _goalPriorityLabel(String goal) {
    final lower = goal.toLowerCase();
    if (lower.contains('giảm mỡ')) return 'Cardio, Core, Chân, Mobility';
    if (lower.contains('tăng cơ')) return 'Push, Pull, Chân, Core';
    if (lower.contains('sức bền')) return 'Cardio, Mobility, Core';
    return 'Cân bằng toàn thân';
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _toViExerciseName(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('squat bodyweight')) {
      return 'Squat với trọng lượng cơ thể';
    }
    if (lower.contains('push-up') || lower.contains('push up')) {
      return 'Hít đất';
    }
    if (lower.contains('plank')) return 'Plank (giữ thân người)';
    if (lower.contains('dumbbell row')) return 'Kéo tạ đơn';
    if (lower.contains('glute bridge')) return 'Nâng hông';
    if (lower.contains('cycling')) return 'Đạp xe';
    if (lower.contains('walking')) return 'Đi bộ';
    if (lower.contains('running') || lower.contains('run')) return 'Chạy bộ';
    if (lower.contains('yoga')) return 'Yoga';
    return input;
  }

  String _toViCategory(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('legs')) return 'Chân';
    if (lower.contains('chest')) return 'Ngực';
    if (lower.contains('back')) return 'Lưng';
    if (lower.contains('core')) return 'Cơ trung tâm';
    if (lower.contains('shoulder')) return 'Vai';
    if (lower.contains('arms')) return 'Tay';
    return input;
  }

  String _localFallbackWorkoutPlan({
    required String goal,
    required String status,
    double? weightKg,
  }) {
    final w = weightKg;
    final lightCardio = (w != null && w >= 85) ? 'Đi bộ nhanh' : 'Chạy bộ nhẹ';
    return [
      'Nguồn: Kế hoạch nội bộ (fallback tiếng Việt)',
      'Mục tiêu: $goal',
      'Trình độ: $status',
      'Cân nặng: ${w?.toStringAsFixed(1) ?? 'chưa cập nhật'} kg',
      '',
      'Bài tập gợi ý:',
      '1. Squat với trọng lượng cơ thể (Chân)',
      '2. Hít đất (Ngực)',
      '3. Plank (Cơ trung tâm)',
      '4. Kéo tạ đơn hoặc kéo cáp (Lưng)',
      '5. Nâng hông (Thân dưới)',
      '6. $lightCardio 15-20 phút',
      '',
      'Lịch đề xuất: 3-4 buổi/tuần, 35-50 phút/buổi.',
    ].join('\n');
  }

  /// 3. Gợi ý thực đơn
  Future<String> getDietRecommendations(String condition, String prefs) async {
    try {
      final model = _requireModel();
      final prompt =
          'Sức khỏe: $condition. Sở thích: ${prefs.isEmpty ? 'Không có yêu cầu đặc biệt' : prefs}. '
          'Hãy tạo một kế hoạch thực đơn tuần cho 7 ngày bằng tiếng Việt, mỗi ngày gồm ít nhất 3 bữa. '
          'Cho biết gợi ý món ăn cho mỗi bữa, kèm lưu ý dinh dưỡng ngắn gọn. '
          'Trả về kết quả rõ ràng theo ngày, dạng văn bản thuần, không có markdown.';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Không có gợi ý.';
    } catch (e) {
      return _toFriendlyAiError(e);
    }
  }
}
