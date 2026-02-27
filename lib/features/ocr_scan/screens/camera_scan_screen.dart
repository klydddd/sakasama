import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/ocr_providers.dart';
import 'package:sakasama/features/ocr_scan/widgets/scan_overlay_painter.dart';

/// Camera scan screen — OCR receipt/label scanner.
///
/// Shows a live camera preview with green scan guide overlay,
/// capture button, gallery picker, and flash toggle.
class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _ensureOcrReady();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _initError = 'Walang camera na nakita.');
        return;
      }

      // Use back camera
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _initError = 'Hindi ma-access ang camera: $e');
    }
  }

  /// Start OCR strategy detection in background.
  void _ensureOcrReady() {
    final initState = ref.read(ocrInitProvider);
    if (initState.status == OcrInitStatus.notReady) {
      ref.read(ocrInitProvider.notifier).initialize();
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final xFile = await _controller!.takePicture();
      if (mounted) {
        context.push('/scan/review', extra: xFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hindi makapag-capture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (xFile != null && mounted) {
      context.push('/scan/review', extra: xFile.path);
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;

    setState(() {
      _flashMode = switch (_flashMode) {
        FlashMode.off => FlashMode.torch,
        FlashMode.torch => FlashMode.auto,
        FlashMode.auto => FlashMode.off,
        _ => FlashMode.off,
      };
    });

    await _controller!.setFlashMode(_flashMode);
  }

  IconData get _flashIcon => switch (_flashMode) {
    FlashMode.off => Icons.flash_off_rounded,
    FlashMode.torch => Icons.flash_on_rounded,
    FlashMode.auto => Icons.flash_auto_rounded,
    _ => Icons.flash_off_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // Watch OCR strategy initialization state
    final initState = ref.watch(ocrInitProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: Text(
          AppStrings.scanTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (initState.status == OcrInitStatus.initializing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          if (initState.status == OcrInitStatus.ready)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: initState.activeStrategy,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Camera Preview Area ─────────────────────────────────────
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera preview or placeholder
                if (_isInitialized && _controller != null)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  )
                else if (_initError != null)
                  _buildErrorPlaceholder()
                else
                  _buildLoadingPlaceholder(),

                // Scan overlay
                CustomPaint(
                  painter: ScanOverlayPainter(
                    borderColor: AppColors.primaryGreen,
                    borderWidth: 3,
                    cornerLength: 35,
                  ),
                  size: Size.infinite,
                ),

                // Instruction text
                Positioned(
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.chipRadius,
                      ),
                    ),
                    child: Text(
                      AppStrings.scanInstruction,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── Bottom Controls ─────────────────────────────────────────
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Capture button
                GestureDetector(
                      onTap: _isCapturing ? null : _captureImage,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? AppColors.textGrey
                                : AppColors.primaryGreen,
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_rounded,
                                  color: AppColors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                    ),

                // Flash toggle
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(_flashIcon, color: AppColors.white, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Ini-load ang camera...',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_rounded,
            size: 64,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            _initError ?? 'Camera error',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _pickFromGallery,
            child: const Text(
              'Pumili mula sa gallery',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
