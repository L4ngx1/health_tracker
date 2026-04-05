class FoodRecognitionResult {
  final String name;
  final double calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final String? description;
  final String? source; // "AI", "USDA", or "Wikipedia"

  FoodRecognitionResult({
    required this.name,
    required this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.description,
    this.source,
  });

  factory FoodRecognitionResult.fromJson(Map<String, dynamic> json) {
    return FoodRecognitionResult(
      name: json['name'] ?? 'Unknown',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      description: json['description'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'description': description,
        'source': source,
      };
}
