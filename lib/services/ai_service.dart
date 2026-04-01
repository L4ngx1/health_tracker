import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/localization/locale_service.dart';
import '../l10n/app_localizations.dart';
import '../models/food_recognition_result.dart';

class AIService {
  // Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyCd1rbUOBU8V64rNQ9EQYN6X_swuqObjtw';

  final GenerativeModel _visionModel;
  final GenerativeModel _textModel;

  AppLocalizations get _l10n =>
      lookupAppLocalizations(LocaleService.instance.locale.value);

  AIService()
    : _visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      ),
      _textModel = GenerativeModel(model: 'gemini-1.5-pro', apiKey: _apiKey);

  /// 1. Nhận diện đồ ăn từ ảnh
  Future<FoodRecognitionResult?> recognizeFood(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            _l10n.aiPromptRecognizeFood,
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ];

      final response = await _visionModel.generateContent(content);
      final text = response.text;

      if (text != null) {
        // Clean the response string if it contains markdown code blocks
        final cleanJson = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        return FoodRecognitionResult.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(_l10n.aiLogRecognizeFoodError('$e'));
      }
    }
    return null;
  }

  /// 2. Gợi ý luyện tập
  Future<String> getWorkoutSuggestions(
    String userGoal,
    String currentStatus,
  ) async {
    try {
      final prompt = _l10n.aiPromptWorkoutSuggestions(userGoal, currentStatus);

      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      return response.text ?? _l10n.aiCouldNotGenerateSuggestions;
    } catch (e) {
      return _l10n.aiErrorGeneric('$e');
    }
  }

  /// 3. Gợi ý chế độ ăn uống
  Future<String> getDietRecommendations(
    String healthCondition,
    String preferences,
  ) async {
    try {
      final prompt = _l10n.aiPromptDietRecommendations(
        healthCondition,
        preferences,
      );

      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      return response.text ?? _l10n.aiCouldNotGenerateRecommendations;
    } catch (e) {
      return _l10n.aiErrorGeneric('$e');
    }
  }
}
