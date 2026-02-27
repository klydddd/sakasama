/// Configuration for a GGUF model used as the OCR fallback strategy.
///
/// Swap models by changing [modelFilename] to point to a different GGUF file
/// in the assets/models/ directory. Supported models include:
/// - GLM-OCR-Q8_0.gguf (current default, ~900MB)
/// - Qwen2.5-1.5B-Instruct-Q4_K_M.gguf (~1GB, recommended upgrade)
/// - Phi-3-mini-4k-instruct-Q4_K_M.gguf (~2.2GB, higher accuracy)
class GgufModelConfig {
  const GgufModelConfig({
    required this.modelFilename,
    this.assetPath = 'assets/models',
    this.contextLength = 4096,
    this.maxTokens = 2048,
    this.temperature = 0.1,
    this.nGpuLayers = 0,
    this.nThreads = 4,
    this.batchSize = 512,
  });

  /// Filename of the GGUF model in [assetPath].
  final String modelFilename;

  /// Asset directory containing the model file.
  final String assetPath;

  /// Maximum context length for the model.
  final int contextLength;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Temperature for generation (lower = more deterministic).
  final double temperature;

  /// GPU layers to offload (0 = CPU only for broader device support).
  final int nGpuLayers;

  /// Number of threads for inference.
  final int nThreads;

  /// Batch size for prompt processing.
  final int batchSize;

  /// Full asset key for loading via rootBundle.
  String get assetKey => '$assetPath/$modelFilename';

  /// Default config — swap [modelFilename] to use a different model.
  static const defaultConfig = GgufModelConfig(
    modelFilename: 'qwen3-1.7b-q8_0.gguf',
  );
}
