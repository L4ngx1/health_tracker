import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/food_recognition_result.dart';
import 'food_data_service.dart';

class AIService {
  // Gemini API Key của bạn
  static const String _apiKey = 'AIzaSyDOHWbg-OMormnpkXR4qTlw0lvq9Hg-h6s';
  final FoodDataService _foodDataService = FoodDataService();

  // Sử dụng Gemini 1.5 Flash - Bản mạnh nhất cho Vision & Text
  final GenerativeModel _model;

  AIService()
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

  /// 1. Nhận diện đồ ăn hoàn toàn bằng API
  Future<FoodRecognitionResult?> recognizeFood(File imageFile) async {
    try {
      debugPrint('--- BẮT ĐẦU NHẬN DIỆN MÓN ĂN QUA API ---');
      
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

      final response = await _model.generateContent(content);
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
      debugPrint('Lỗi AI Service: $e');
    }
    return null;
  }

  /// 2. Gợi ý tập luyện
  Future<String> getWorkoutSuggestions(String goal, String status) async {
    try {
      final prompt = 'Mục tiêu: $goal. Trình độ: $status. Gợi ý lịch tập ngắn gọn bằng tiếng Việt.';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Không có gợi ý.';
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  /// 3. Gợi ý thực đơn
  Future<String> getDietRecommendations(String condition, String prefs) async {
    try {
      final prompt = 'Sức khỏe: $condition. Sở thích: $prefs. Gợi ý thực đơn bằng tiếng Việt.';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Không có gợi ý.';
    } catch (e) {
      return 'Lỗi: $e';
    }
  }
}
