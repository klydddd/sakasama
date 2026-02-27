import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sakasama_vlm_platform_interface.dart';

/// An implementation of [SakasamaVlmPlatform] that uses method channels.
class MethodChannelSakasamaVlm extends SakasamaVlmPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sakasama_vlm');

  @override
  Future<String?> scanImageWithGotOcr({
    required String imagePath,
    required String baseModelPath,
    required String visionModelPath,
    required String prompt,
  }) async {
    final result = await methodChannel
        .invokeMethod<String>('scanImageWithGotOcr', {
          'imagePath': imagePath,
          'baseModelPath': baseModelPath,
          'visionModelPath': visionModelPath,
          'prompt': prompt,
        });
    return result;
  }

  @override
  Future<bool> copyAssetToPath({
    required String assetKey,
    required String targetPath,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('copyAssetToPath', {
      'assetKey': assetKey,
      'targetPath': targetPath,
    });
    return result ?? false;
  }
}
