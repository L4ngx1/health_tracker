import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/common_widgets.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _cameraError;
  bool _isInitializingCamera = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraPreview();
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
          _cameraError = 'Khong tim thay camera tren thiet bi.';
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError =
            'Khong the mo camera. Vui long cap quyen camera va thu lai.';
      });
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<void> _captureFromPreview() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile shot = await controller.takePicture();
      if (!mounted) return;

      setState(() {
        _selectedImage = File(shot.path);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong the chup anh. Vui long thu lai.')),
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

      setState(() {
        _selectedImage = File(picked.path);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Khong the truy cap thu vien anh. Vui long cap quyen va thu lai.',
          ),
        ),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _selectedImage = null;
    });

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _initializeCameraPreview();
    }
  }

  Widget _buildPreviewBox() {
    final CameraController? controller = _cameraController;
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        width: double.infinity,
        height: 330,
        fit: BoxFit.cover,
      );
    }

    final bool canShowLive =
        controller != null && controller.value.isInitialized;
    if (canShowLive) {
      return SizedBox(
        width: double.infinity,
        height: 330,
        child: CameraPreview(controller),
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
              color: Colors.black.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  _cameraError!,
                  style: const TextStyle(
                    color: Colors.white,
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
                title: 'Dự đoán dinh dưỡng',
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Chụp hoặc tải ảnh món ăn để AI dự đoán\nlượng Calories',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textMuted),
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
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '# AI Ready',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _retakePhoto,
                            tooltip: 'Chup lai',
                            icon: const Icon(
                              Icons.replay_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _captureFromPreview,
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: AppPalette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    _isCapturing ? 'Dang chup...' : 'Chụp ảnh',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickFoodImage,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppPalette.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: AppPalette.primaryDark,
                ),
                label: const Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(
                    color: AppPalette.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppPalette.highlight,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1B7D5B),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFFF6C89A),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: AppPalette.primaryDark,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mẹo nhỏ',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Hãy đảm bảo thức ăn được chiếu sáng\ntốt để AI có thể nhận diện thành phần\nchính xác nhất.',
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
