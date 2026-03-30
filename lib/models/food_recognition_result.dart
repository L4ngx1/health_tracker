class FoodRecognitionResult {
  final String name;
  final double calories;
  final String? description;

  FoodRecognitionResult({
    required this.name,
    required this.calories,
    this.description,
  });

  factory FoodRecognitionResult.fromJson(Map<String, dynamic> json) {
    return FoodRecognitionResult(
      name: json['name'] ?? 'Unknown',
      calories: (json['calories'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}
