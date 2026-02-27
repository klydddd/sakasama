import 'dart:convert';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sakasama/core/config/gguf_model_config.dart';
import 'package:sakasama/core/services/ocr_strategy.dart';
import 'package:sakasama/core/services/receipt_parser.dart';
import 'package:sakasama/core/services/spatial_text_formatter.dart';
import 'package:sakasama/data/models/ocr_result.dart';

/// Hybrid offline OCR service with automatic strategy selection.
///
/// **Pipeline:**
/// 1. ML Kit extracts text blocks with bounding boxes.
/// 2. [SpatialTextFormatter] reconstructs the receipt layout.
/// 3. Best available [OcrStrategy] extracts structured JSON:
///    - [GeminiNanoStrategy] (primary) on supported devices.
///    - [GgufModelStrategy] (fallback) on all other devices.
/// 4. If both fail, falls back to [ReceiptParser] heuristics.
///
/// No internet connection required.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  OcrStrategy? _activeStrategy;
  bool _isProcessing = false;
  bool _isInitialized = false;

  // GGUF config — change this to swap models.
  GgufModelConfig _ggufConfig = GgufModelConfig.defaultConfig;

  /// Whether an inference is currently in progress.
  bool get isProcessing => _isProcessing;

  /// Name of the active OCR strategy (for UI display).
  String get activeStrategyName => _activeStrategy?.name ?? 'Wala pa';

  /// Whether the service has been initialized with a strategy.
  bool get isInitialized => _isInitialized;

  /// Override the GGUF model config (call before [initialize]).
  void setGgufConfig(GgufModelConfig config) {
    _ggufConfig = config;
  }

  /// Initialize: detect the best available strategy.
  ///
  /// Call this once at app startup or before first scan.
  Future<void> initialize({void Function(String status)? onStatus}) async {
    if (_isInitialized) return;

    // 1. Try Gemini Nano (primary — fast, accurate, no bundling)
    onStatus?.call('Sinusuri ang Gemini Nano...');
    final geminiStrategy = GeminiNanoStrategy();
    if (await geminiStrategy.isAvailable()) {
      _activeStrategy = geminiStrategy;
      _isInitialized = true;
      onStatus?.call('Gagamitin ang Gemini Nano.');
      return;
    }

    // 2. Fall back to GGUF model (universal)
    onStatus?.call('Ini-setup ang GGUF model...');
    final ggufStrategy = GgufModelStrategy(config: _ggufConfig);
    try {
      if (await ggufStrategy.isAvailable()) {
        await ggufStrategy.initialize();
        _activeStrategy = ggufStrategy;
        _isInitialized = true;
        onStatus?.call('Gagamitin ang ${ggufStrategy.name}.');
        return;
      }
    } catch (e) {
      // GGUF failed — continue to heuristic fallback
      onStatus?.call('Hindi ma-load ang GGUF: $e');
    }

    // 3. No LLM available — will use heuristic fallback
    _isInitialized = true;
    onStatus?.call('Gagamitin ang heuristic parsing.');
  }

  /// Run the full OCR pipeline on an image file.
  Future<OcrResult> processImage(String imagePath) async {
    if (_isProcessing) {
      throw StateError('May kasalukuyang OCR na ginagawa.');
    }

    _isProcessing = true;

    try {
      // ── Stage 1: ML Kit text extraction ───────────────────────────
      final recognizedText = await _recognizeText(imagePath);

      if (recognizedText.text.trim().isEmpty) {
        return OcrResult.fromRawText(
          '(Walang text na nakita sa image)',
          imagePath: imagePath,
        );
      }

      // ── Stage 2: Spatial formatting ───────────────────────────────
      final spatialText = SpatialTextFormatter.format(recognizedText);

      // ── Stage 3: Strategy-based extraction ────────────────────────
      if (_activeStrategy != null) {
        try {
          final rawJson = await _activeStrategy!.extract(spatialText);
          final result = _parseJsonOutput(
            rawJson,
            imagePath: imagePath,
            rawText: recognizedText.text,
          );

          if (result.hasStructuredData) {
            return result;
          }
        } catch (_) {
          // Strategy failed — fall through to heuristic
        }
      }

      // ── Stage 4: Heuristic fallback ───────────────────────────────
      final parsed = ReceiptParser.parse(recognizedText);
      final confidence = parsed['confidence'] as Map<String, bool>? ?? {};

      return OcrResult(
        product: parsed['product'] as String?,
        activeIngredient: parsed['active_ingredient'] as String?,
        dosage: parsed['dosage'] as String?,
        manufacturer: parsed['manufacturer'] as String?,
        netWeight: parsed['net_weight'] as String?,
        expiryDate: parsed['expiry_date'] as String?,
        registrationNo: parsed['registration_no'] as String?,
        rawText: recognizedText.text,
        imagePath: imagePath,
        confidence: Map<String, bool>.from(confidence),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Extract text from image using Google ML Kit.
  Future<RecognizedText> _recognizeText(String imagePath) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await textRecognizer.processImage(inputImage);
    } finally {
      textRecognizer.close();
    }
  }

  /// Parse raw LLM output into an [OcrResult].
  OcrResult _parseJsonOutput(
    String output, {
    String? imagePath,
    String? rawText,
  }) {
    try {
      String jsonStr = output;

      // Strip ```json ... ``` wrapping
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json').last.split('```').first.trim();
      } else if (jsonStr.contains('```')) {
        jsonStr =
            jsonStr
                .split('```')
                .where((s) => s.trim().startsWith('{'))
                .firstOrNull
                ?.trim() ??
            jsonStr;
      }

      // Find the JSON object
      final startIdx = jsonStr.indexOf('{');
      final endIdx = jsonStr.lastIndexOf('}');
      if (startIdx != -1 && endIdx > startIdx) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // All fields from LLM are high confidence
      final confidence = <String, bool>{
        'product': json['product'] != null,
        'activeIngredient': json['active_ingredient'] != null,
        'dosage': json['dosage'] != null,
        'manufacturer': json['manufacturer'] != null,
        'netWeight': json['net_weight'] != null,
        'expiryDate': json['expiry_date'] != null,
        'registrationNo': json['registration_no'] != null,
      };

      return OcrResult(
        product: json['product']?.toString(),
        activeIngredient: json['active_ingredient']?.toString(),
        dosage: json['dosage']?.toString(),
        manufacturer: json['manufacturer']?.toString(),
        netWeight: json['net_weight']?.toString(),
        expiryDate: json['expiry_date']?.toString(),
        registrationNo: json['registration_no']?.toString(),
        rawText: rawText,
        imagePath: imagePath,
        confidence: confidence,
      );
    } catch (_) {
      return OcrResult.fromRawText(output, imagePath: imagePath);
    }
  }

  /// Unload the active strategy and free memory.
  Future<void> dispose() async {
    await _activeStrategy?.dispose();
    _activeStrategy = null;
    _isInitialized = false;
    _isProcessing = false;
  }
}
