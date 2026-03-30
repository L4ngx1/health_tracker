import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/ai_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';
import '../../models/food_recognition_result.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final AIController _aiController = AIController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  FoodRecognitionResult? _result;
  String? _dietRecommendation;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
      _recognizeFood();
    }
  }

  Future<void> _recognizeFood() async {
    if (_image == null) return;
    setState(() => _isLoading = true);
    final result = await _aiController.scanFood(_image!);
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<void> _getDietPlan() async {
    setState(() => _isLoading = true);
    // In a real app, you'd get these from user profile
    final recommendation = await _aiController.getPersonalizedDiet(
        "Cân nặng bình thường, huyết áp hơi cao", "Ít carb, ưu tiên rau củ");
    setState(() {
      _dietRecommendation = recommendation;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EC), Color(0xFFF2F8F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Dinh dưỡng AI',
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 8),
              if (_image == null)
                const Center(
                  child: Text(
                    'Chụp hoặc tải ảnh món ăn để AI dự đoán\nlượng Calories',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppPalette.textMuted),
                  ),
                ),
              const SizedBox(height: 10),
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    _image!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1546793665-c74683f339c1?auto=format&fit=crop&w=900&q=80',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_result != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ước tính: ${_result!.calories} kcal / 100g',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      if (_result!.description != null) ...[
                        const SizedBox(height: 8),
                        Text(_result!.description!),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppPalette.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Thư viện'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Chế độ ăn gợi ý',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_dietRecommendation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.highlight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_dietRecommendation!),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getDietPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Nhận gợi ý ăn uống AI'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
