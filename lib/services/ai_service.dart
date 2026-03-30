import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_recognition_result.dart';

class AIService {
  // Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyCd1rbUOBU8V64rNQ9EQYN6X_swuqObjtw';
  
  final GenerativeModel _visionModel;
  final GenerativeModel _textModel;

  AIService()
      : _visionModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey),
        _textModel = GenerativeModel(model: 'gemini-1.5-pro', apiKey: _apiKey);

  /// 1. Nhận diện đồ ăn từ ảnh
  Future<FoodRecognitionResult?> recognizeFood(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              'Identify the food in this image. Provide the name and estimated calories per 100g. '
              'Return only a JSON object like: {"name": "...", "calories": 0.0, "description": "..."}'),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      final text = response.text;
      
      if (text != null) {
        // Clean the response string if it contains markdown code blocks
        final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        return FoodRecognitionResult.fromJson(data);
      }
    } catch (e) {
      print('Error recognizing food: $e');
    }
    return null;
  }

  /// 2. Gợi ý luyện tập
  Future<String> getWorkoutSuggestions(String userGoal, String currentStatus) async {
    try {
      final prompt = 'Based on the user goal: $userGoal and current status: $currentStatus, '
          'suggest a daily workout routine. Keep it concise and practical.';
      
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      return response.text ?? 'Could not generate suggestions.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// 3. Gợi ý chế độ ăn uống
  Future<String> getDietRecommendations(String healthCondition, String preferences) async {
    try {
      final prompt = 'User health condition: $healthCondition. Preferences: $preferences. '
          'Provide a recommended diet plan and foods to avoid.';
      
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      return response.text ?? 'Could not generate recommendations.';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
