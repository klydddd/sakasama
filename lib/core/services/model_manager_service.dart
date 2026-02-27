import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sakasama_vlm/sakasama_vlm.dart';

/// Handles copying the massive GOT-OCR 2.0 models from assets
class ModelManagerService {
  ModelManagerService._privateConstructor();
  static final ModelManagerService instance =
      ModelManagerService._privateConstructor();

  final _vlm = SakasamaVlm();

  // Selected models from assets/models folder
  static const String baseModelFilename = 'GOT-OCR2_0-716M-BF16.gguf';
  static const String visionModelFilename =
      'llava-llama-3-8b-v1_1-mmproj-f16.gguf';

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  /// Stream to listen for setup progress (0.0 to 1.0)
  Stream<double> get progressStream => _progressController.stream;

  /// Returns the absolute path to the directory where models are stored.
  Future<String> getModelsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${directory.path}/ai_models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  /// Checks if both required models exist on the device and are valid structurally (not partial).
  Future<bool> areModelsDownloaded() async {
    final modelsDir = await getModelsDirectory();
    final baseModel = File('$modelsDir/$baseModelFilename');
    final visionModel = File('$modelsDir/$visionModelFilename');

    if (await baseModel.exists() && await visionModel.exists()) {
      // Validate file size to recover from previous Out-Of-Memory partial writes
      final baseSize = await baseModel.length();
      final visionSize = await visionModel.length();

      // Base model should belong to the ~1GB+ realm, Vision is ~500MB+ depending on quantization
      // Checking for arbitrary > 50MB to just catch 0-byte or heavily truncated crashes
      if (baseSize > 50 * 1024 * 1024 && visionSize > 10 * 1024 * 1024) {
        return true;
      }

      // If they exist but are corrupted/partial, delete them so they can be securely recopied
      debugPrint(
        "Warning: Models appear corrupted (partial). Deleting to retry.",
      );
      await baseModel.delete();
      await visionModel.delete();
    }

    return false;
  }

  /// Copies models from assets to the documents directory, emitting progress.
  Future<void> downloadModels() async {
    try {
      if (await areModelsDownloaded()) {
        _progressController.add(1.0);
        return;
      }

      final modelsDir = await getModelsDirectory();
      final assets = [baseModelFilename, visionModelFilename];

      double totalProgress = 0.0;
      final step = 1.0 / assets.length;

      for (final filename in assets) {
        final targetPath = '$modelsDir/$filename';
        final targetFile = File(targetPath);

        // Delete if exists but is invalid (though areModelsDownloaded handles most cases)
        if (await targetFile.exists() && await targetFile.length() < 1000) {
          await targetFile.delete();
        }

        if (!await targetFile.exists()) {
          // Copy from assets using memory-efficient native code
          await _vlm.copyAssetToPath(
            assetKey: 'assets/models/$filename',
            targetPath: targetPath,
          );
        }

        totalProgress += step;
        _progressController.add(totalProgress.clamp(0.0, 1.0));
      }

      _progressController.add(1.0);
      debugPrint("Models initialized successfully at $modelsDir");
    } catch (e) {
      debugPrint("Error initializing models: $e");
      _progressController.addError(e);
      rethrow;
    }
  }

  /// Returns the absolute path of the base model.
  Future<String?> getBaseModelPath() async {
    final modelsDir = await getModelsDirectory();
    final file = File('$modelsDir/$baseModelFilename');
    return await file.exists() ? file.path : null;
  }

  /// Returns the absolute path of the vision projector model.
  Future<String?> getVisionModelPath() async {
    final modelsDir = await getModelsDirectory();
    final file = File('$modelsDir/$visionModelFilename');
    return await file.exists() ? file.path : null;
  }
}
