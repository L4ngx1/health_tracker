import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/ai_controller.dart';
import '../../models/food_recognition_result.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/common_widgets.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();
  final AIController _aiController = AIController();

  Uint8List? _selectedImageBytes;
  String? _cameraError;
  bool _isInitializingCamera = false;
  bool _isCapturing = false;
  
  bool _isAnalyzing = false;
  FoodRecognitionResult? _analysisResult;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCameraPreview() async {
    if (_isInitializingCamera) {
      return;
    }

    _isInitializingCamera = true;
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraError = AppStrings.cameraNotFound(context);
        });
        return;
      }

      CameraDescription selected = cameras.first;
      for (final CameraDescription camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selected = camera;
          break;
        }
      }

      await _cameraController?.dispose();

      final CameraController controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessRestricted') {
        setState(() {
          _cameraError = AppStrings.cameraOpenFailed(context);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.cameraOpenFailed(context))),
        );
        return;
      }

      if (e.code == 'CameraAccessDeniedWithoutPrompt') {
        setState(() {
          _cameraError = AppStrings.cameraOpenFailed(context);
        });
        await _showOpenSettingsDialog();
        return;
      }

      setState(() {
        _cameraError = AppStrings.cameraOpenFailed(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = AppStrings.cameraOpenFailed(context);
      });
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<void> _showOpenSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Camera permission required'),
        content: const Text(
          'Please allow camera access in Settings to take food photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await Geolocator.openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final result = await _aiController.scanFood(imageBytes);
      if (mounted) {
        setState(() {
          _analysisResult = result;
        });
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Khong nhan duoc ket qua AI. Kiem tra GEMINI_API_KEY trong assets/env/.env va khoi dong lai app.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phân tích ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _captureFromPreview() async {
    if (_isCapturing || _isInitializingCamera) {
      return;
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _initializeCameraPreview();
      // First tap should only request permission/open camera preview.
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile shot = await controller.takePicture();
      if (!mounted) return;

      final Uint8List imageBytes = await shot.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
      });
      
      // Tự động phân tích sau khi chụp
      _analyzeImage(imageBytes);
      
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.capturePhotoFailed(context))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickFoodImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (!mounted || picked == null) {
        return;
      }

      final Uint8List imageBytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
      });
      
      // Tự động phân tích sau khi chọn từ thư viện
      _analyzeImage(imageBytes);
      
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.galleryAccessFailed(context))),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _selectedImageBytes = null;
      _analysisResult = null;
    });

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _initializeCameraPreview();
    }
  }

  Widget _buildPreviewBox() {
    final CameraController? controller = _cameraController;
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        width: double.infinity,
        height: 330,
        fit: BoxFit.cover,
      );
    }

    final bool canShowLive =
        controller != null && controller.value.isInitialized;
    if (canShowLive) {
      final previewSize = controller.value.previewSize;
      final previewWidth = previewSize?.height ?? 1080;
      final previewHeight = previewSize?.width ?? 1920;
      return SizedBox(
        width: double.infinity,
        height: 330,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewWidth,
              height: previewHeight,
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1546793665-c74683f339c1?auto=format&fit=crop&w=900&q=80',
          width: double.infinity,
          height: 330,
          fit: BoxFit.cover,
        ),
        if (_cameraError != null)
          Positioned.fill(
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.scrim.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  _cameraError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool aiEnabled = _aiController.isAiConfigured;
    final bool isCameraReady =
        _cameraController != null && _cameraController!.value.isInitialized;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
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
                title: AppStrings.nutritionScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppStrings.nutritionAiSubtitle(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    _buildPreviewBox(),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.scrim.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          AppStrings.aiReadyTag(context),
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImageBytes != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.scrim.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _retakePhoto,
                            tooltip: AppStrings.retakePhotoTooltip(context),
                            icon: Icon(
                              Icons.replay_rounded,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Hiển thị kết quả phân tích AI
              if (_isAnalyzing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Đang phân tích món ăn...'),
                      ],
                    ),
                  ),
                ),

              if (!aiEnabled)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'AI dang tam khoa do thieu GEMINI_API_KEY trong assets/env/.env',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                
              if (_analysisResult != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _analysisResult!.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_analysisResult!.calories.toInt()} kcal',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_analysisResult!.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _analysisResult!.description!,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 14),
              if (_selectedImageBytes == null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: (!aiEnabled || _isCapturing)
                        ? null
                        : _captureFromPreview,
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _isCapturing
                          ? AppStrings.capturingPhoto(context)
                          : isCameraReady
                              ? AppStrings.capturePhoto(context)
                              : (AppStrings.isEnglish(context)
                                  ? 'Open camera'
                                  : 'Mở camera'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: aiEnabled ? _pickFoodImage : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(
                    Icons.photo_library_outlined,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    AppStrings.pickFromLibrary(context),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.secondary.withValues(alpha: 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.secondary.withValues(
                        alpha: 0.38,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tipTitle(context),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            AppStrings.tipDescription(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
