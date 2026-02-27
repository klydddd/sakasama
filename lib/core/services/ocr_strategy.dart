import 'dart:io';

import 'package:flutter_llama/flutter_llama.dart';
import 'package:gemini_nano_android/gemini_nano_android.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:sakasama/core/config/gguf_model_config.dart';

// ── Abstract Strategy ──────────────────────────────────────────────────

/// Abstract OCR extraction strategy.
///
/// Both [GeminiNanoStrategy] and [GgufModelStrategy] implement this
/// interface. The [OcrService] picks the best available strategy at runtime.
abstract class OcrStrategy {
  /// Human-readable name for UI display (e.g., "Gemini Nano").
  String get name;

  /// Check if this strategy can run on the current device.
  Future<bool> isAvailable();

  /// Initialize the strategy (e.g., load model). No-op if already ready.
  Future<void> initialize();

  /// Extract structured fields from spatially-formatted receipt text.
  ///
  /// [spatialText] is the output of [SpatialTextFormatter.format].
  /// Returns a JSON-decodable string with keys: product, price,
  /// quantity, supplier, date.
  Future<String> extract(String spatialText);

  /// Free resources.
  Future<void> dispose();

  /// Default structuring prompt sent to the model.
  static String structuringPrompt(String spatialText) =>
      '''You are an agricultural product label data extractor. You receive spatially-formatted text from a product label (fertilizer, pesticide, herbicide, or other farm input) where:
- [LARGEST TEXT] = header area (product name, brand, logo text)
- [MID] = details area (ingredients, instructions, dosage, weight)
- [BOT] = footer area (manufacturer, registration, expiry, warnings)

Extract ONLY these fields and output ONLY valid JSON, no other text:
{
  "product": "full product name",
  "active_ingredient": "active ingredient(s) with concentration if shown",
  "dosage": "recommended dosage or application rate",
  "manufacturer": "manufacturer or brand name",
  "net_weight": "net weight or volume with unit (e.g. 50 kg, 1 L)",
  "expiry_date": "expiry or manufacturing date in YYYY-MM-DD format",
  "registration_no": "FPA or government registration number"
}

If a field is not found, use null.

Product label text:
"""
$spatialText
"""

JSON:''';
}

// ── Gemini Nano Strategy ───────────────────────────────────────────────

/// Primary OCR strategy using on-device Gemini Nano via Android AI Core.
///
/// Zero model bundling — the model is managed by the OS.
/// Only available on supported devices (Pixel 9+, Galaxy S25+, etc.)
class GeminiNanoStrategy extends OcrStrategy {
  final GeminiNanoAndroid _gemini = GeminiNanoAndroid();

  @override
  String get name => 'Gemini Nano';

  @override
  Future<bool> isAvailable() async {
    try {
      return await _gemini.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    // No initialization needed — AI Core manages the model.
  }

  @override
  Future<String> extract(String spatialText) async {
    final prompt = OcrStrategy.structuringPrompt(spatialText);

    final results = await _gemini.generate(
      prompt: prompt,
      temperature: 0.1,
      candidateCount: 1,
    );

    if (results.isEmpty) {
      throw StateError('Gemini Nano returned empty results.');
    }

    return results.first;
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed — AI Core manages lifecycle.
  }
}

// ── GGUF Model Strategy ────────────────────────────────────────────────

/// Fallback OCR strategy using a GGUF model via llama.cpp (flutter_llama).
///
/// Works on ALL Android devices. The model file is bundled in assets/models/
/// and copied to app data on first use.
///
/// To swap models, change [GgufModelConfig.modelFilename] to point to
/// a different GGUF file (e.g., Qwen2.5-1.5B, Phi-3-mini).
class GgufModelStrategy extends OcrStrategy {
  GgufModelStrategy({GgufModelConfig? config})
    : _config = config ?? GgufModelConfig.defaultConfig;

  final GgufModelConfig _config;
  FlutterLlama? _llama;
  bool _isLoaded = false;
  String? _modelPath;

  @override
  String get name => 'GGUF: ${_config.modelFilename}';

  @override
  Future<bool> isAvailable() async {
    // Quick check: is the model file already copied to app storage?
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File(
        p.join(appDir.path, 'models', _config.modelFilename),
      );
      return modelFile.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    if (_isLoaded) return;

    // Ensure model file is on disk
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(appDir.path, 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    _modelPath = p.join(modelsDir.path, _config.modelFilename);
    final modelFile = File(_modelPath!);

    if (!await modelFile.exists()) {
      throw StateError(
        'GGUF model file not found: ${_config.modelFilename}. '
        'Copy it to ${modelsDir.path} first.',
      );
    }

    // Load via flutter_llama (lazy init to avoid native crashes on startup)
    _llama ??= FlutterLlama.instance;

    final config = LlamaConfig(
      modelPath: _modelPath!,
      nThreads: _config.nThreads,
      nGpuLayers: _config.nGpuLayers,
      contextSize: _config.contextLength,
      batchSize: _config.batchSize,
      useGpu: false,
      verbose: false,
    );

    final success = await _llama!.loadModel(config);
    if (!success) {
      throw StateError(
        'Hindi ma-load ang GGUF model: ${_config.modelFilename}',
      );
    }

    _isLoaded = true;
  }

  @override
  Future<String> extract(String spatialText) async {
    if (!_isLoaded) {
      await initialize();
    }

    final prompt = OcrStrategy.structuringPrompt(spatialText);

    final params = GenerationParams(
      prompt: prompt,
      maxTokens: _config.maxTokens,
      temperature: _config.temperature,
      topK: 40,
      topP: 0.9,
      repeatPenalty: 1.1,
    );

    final response = await _llama!.generate(params);
    return response.text.trim();
  }

  @override
  Future<void> dispose() async {
    if (_isLoaded && _llama != null) {
      await _llama!.unloadModel();
    }
    _isLoaded = false;
  }
}
