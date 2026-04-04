import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/food_recognition_result.dart';

class FoodDataService {
  // USDA API Key (get from https://fdc.nal.usda.gov/api-key-signup.html)
  static const String _usdaApiKey = 'DEMO_KEY'; // Use DEMO_KEY for limited usage

  /// 1. Tìm kiếm dữ liệu từ USDA (Chính xác cho thực phẩm Mỹ/Quốc tế)
  Future<FoodRecognitionResult?> searchUSDA(String foodName) async {
    try {
      final url = Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$_usdaApiKey&query=$foodName&pageSize=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['foods'] != null && data['foods'].isNotEmpty) {
          final food = data['foods'][0];
          final nutrients = food['foodNutrients'] as List;

          // Tìm các chỉ số quan trọng
          double calories = 0, protein = 0, fat = 0, carbs = 0;
          for (var n in nutrients) {
            final name = n['nutrientName'].toString().toLowerCase();
            if (name.contains('energy') && n['unitName'] == 'KCAL') calories = n['value'].toDouble();
            if (name.contains('protein')) protein = n['value'].toDouble();
            if (name.contains('total lipid')) fat = n['value'].toDouble();
            if (name.contains('carbohydrate')) carbs = n['value'].toDouble();
          }

          return FoodRecognitionResult(
            name: food['description'],
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            description: 'Dữ liệu từ USDA FoodData Central',
            source: 'USDA',
          );
        }
      }
    } catch (e) {
      debugPrint('USDA Search Error: $e');
    }
    return null;
  }

  /// 2. Crawl dữ liệu từ Wikipedia (Cho thông tin tổng quan)
  Future<FoodRecognitionResult?> crawlWikipedia(String foodName) async {
    try {
      final url = Uri.parse('https://en.wikipedia.org/wiki/$foodName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var document = parse(response.body);
        // Tìm bảng thông tin dinh dưỡng (infobox)
        var infobox = document.querySelector('.infobox');
        if (infobox != null) {
          // Wikipedia scraping là một kỹ thuật khó vì cấu trúc thay đổi
          // Đây là ví dụ đơn giản lấy đoạn mô tả đầu tiên
          var description = document.querySelector('p')?.text ?? '';
          
          return FoodRecognitionResult(
            name: foodName,
            calories: 0, // Wikipedia không trả về JSON chuẩn cho calories dễ dàng
            description: description.substring(0, description.length > 200 ? 200 : description.length),
            source: 'Wikipedia',
          );
        }
      }
    } catch (e) {
      debugPrint('Wikipedia Crawl Error: $e');
    }
    return null;
  }
}
