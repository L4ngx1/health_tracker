import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
        'GEMINI_API_KEY is missing. Set --dart-define=GEMINI_API_KEY=...'
      );
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
    if (raw.contains('missing') && raw.contains('gemini_api_key')) {
      return 'Chua cau hinh GEMINI_API_KEY trong assets/env/.env (hoac --dart-define).';
    }

    return 'Khong the ket noi dich vu AI luc nay. Vui long thu lai sau.';
  }

  /// 1. Nhận diện đồ ăn hoàn toàn bằng API
  Future<FoodRecognitionResult?> recognizeFood(File imageFile) async {
    try {
      debugPrint('--- BẮT ĐẦU NHẬN DIỆN MÓN ĂN QUA API ---');
      final model = _requireModel();
      
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            'Analyze this food image. Return ONLY a JSON object with this format: '
            '{"name_en": "Common English Name", "name_vi": "Tên tiếng Việt chính xác", "calories_est": 0.0, "description": "Short description"}. '
            'Be accurate and only return JSON.'
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null) {
        debugPrint('Gemini Response: $text');
        
        // Làm sạch chuỗi JSON
        String jsonStr = text.replaceAll('```json', '').replaceAll('```', '').trim();
        if (jsonStr.contains('{') && jsonStr.contains('}')) {
          jsonStr = jsonStr.substring(jsonStr.indexOf('{'), jsonStr.lastIndexOf('}') + 1);
        }
        
        final Map<String, dynamic> aiData = jsonDecode(jsonStr);
        String nameEn = aiData['name_en'] ?? '';
        String nameVi = aiData['name_vi'] ?? 'Món ăn lạ';
        double calEst = (aiData['calories_est'] ?? 0).toDouble();
        String desc = aiData['description'] ?? '';

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
  Future<String> getWorkoutSuggestions(String goal, String status) async {
    try {
      final model = _requireModel();
      final prompt = 'Mục tiêu: $goal. Trình độ: $status. Gợi ý lịch tập ngắn gọn bằng tiếng Việt.';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Không có gợi ý.';
    } catch (e) {
      return _toFriendlyAiError(e);
    }
  }

  /// 3. Gợi ý thực đơn
  Future<String> getDietRecommendations(String condition, String prefs) async {
    try {
      final model = _requireModel();
      final prompt = 'Sức khỏe: $condition. Sở thích: $prefs. Gợi ý thực đơn bằng tiếng Việt.';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Không có gợi ý.';
    } catch (e) {
      return _toFriendlyAiError(e);
    }
  }
}
