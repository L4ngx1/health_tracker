import 'dart:io';
import '../services/ai_service.dart';
import '../models/food_recognition_result.dart';

class AIController {
  final AIService _aiService = AIService();

  Future<FoodRecognitionResult?> scanFood(File imageFile) async {
    return await _aiService.recognizeFood(imageFile);
  }

  Future<String> getPersonalizedWorkout(String goal, String status) async {
    return await _aiService.getWorkoutSuggestions(goal, status);
  }

  Future<String> getPersonalizedDiet(String condition, String preferences) async {
    return await _aiService.getDietRecommendations(condition, preferences);
  }
}
