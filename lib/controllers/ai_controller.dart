import 'dart:typed_data';
import '../services/ai_service.dart';
import '../models/food_recognition_result.dart';

class AIController {
  final AIService _aiService = AIService();

  bool get isAiConfigured => _aiService.isAiConfigured;

  Future<FoodRecognitionResult?> scanFood(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    return await _aiService.recognizeFood(imageBytes, mimeType: mimeType);
  }

  Future<String> getPersonalizedWorkout(
    String goal,
    String status, {
    double? weightKg,
  }) async {
    return await _aiService.getWorkoutSuggestions(
      goal,
      status,
      weightKg: weightKg,
    );
  }

  Future<String> getPersonalizedDiet(
      String condition, String preferences) async {
    return await _aiService.getDietRecommendations(condition, preferences);
  }
}
