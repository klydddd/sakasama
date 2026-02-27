import 'sakasama_vlm_platform_interface.dart';

class SakasamaVlm {
  /// Passes an image to the native GOT-OCR engine.
  Future<String?> scanImageWithGotOcr({
    required String imagePath,
    required String baseModelPath,
    required String visionModelPath,
    required String prompt,
  }) {
    return SakasamaVlmPlatform.instance.scanImageWithGotOcr(
      imagePath: imagePath,
      baseModelPath: baseModelPath,
      visionModelPath: visionModelPath,
      prompt: prompt,
    );
  }

  /// Copies an asset to a local file path using native streams.
  Future<bool> copyAssetToPath({
    required String assetKey,
    required String targetPath,
  }) {
    return SakasamaVlmPlatform.instance.copyAssetToPath(
      assetKey: assetKey,
      targetPath: targetPath,
    );
  }
}
