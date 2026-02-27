import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sakasama_vlm_method_channel.dart';

abstract class SakasamaVlmPlatform extends PlatformInterface {
  /// Constructs a SakasamaVlmPlatform.
  SakasamaVlmPlatform() : super(token: _token);

  static final Object _token = Object();

  static SakasamaVlmPlatform _instance = MethodChannelSakasamaVlm();

  /// The default instance of [SakasamaVlmPlatform] to use.
  ///
  /// Defaults to [MethodChannelSakasamaVlm].
  static SakasamaVlmPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SakasamaVlmPlatform] when
  /// they register themselves.
  static set instance(SakasamaVlmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Scans an image natively using GOT-OCR 2.0.
  Future<String?> scanImageWithGotOcr({
    required String imagePath,
    required String baseModelPath,
    required String visionModelPath,
    required String prompt,
  });

  /// Copies an asset to a local file path using native streams (memory efficient).
  Future<bool> copyAssetToPath({
    required String assetKey,
    required String targetPath,
  });
}
