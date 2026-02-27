import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/services/model_manager_service.dart';

/// Screen that forces the user to download the massive AI models before
/// they can use the app. Connects to `ModelManagerService`.
class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  double _progress = 0.0;
  bool _isDownloading = false;
  bool _hasError = false;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _checkExistingModels();
  }

  Future<void> _checkExistingModels() async {
    final exists = await ModelManagerService.instance.areModelsDownloaded();
    if (exists && mounted) {
      context.go('/onboarding/language');
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
    });

    _progressSub = ModelManagerService.instance.progressStream.listen(
      (progress) {
        setState(() {
          _progress = progress;
        });
        if (progress >= 1.0) {
          _progressSub?.cancel();
          if (mounted) {
            context.go('/onboarding/language');
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _hasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nabigong i-set up ang AI: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );

    try {
      await ModelManagerService.instance.downloadModels();
    } catch (e) {
      // Stream listener catches error
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.memory_rounded,
                size: 80,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: AppDimensions.sectionSpacing),
              const Text(
                'AI Scanner Setup',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937), // gray-800
                ),
              ),
              const SizedBox(height: AppDimensions.itemSpacing),
              const Text(
                'I-aayos natin ang Offline AI Scanner para sa iyong mobile. Sandali lamang at huwag isara ang app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4B5563), // gray-600
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.sectionSpacing * 2),

              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.lightGreen,
                  color: AppColors.primaryGreen,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.buttonRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Simulan ang Setup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_hasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Nagkaroon ng problema. Subukang muli.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
