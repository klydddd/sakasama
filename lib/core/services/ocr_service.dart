import 'dart:convert';

import 'package:sakasama/data/models/ocr_result.dart';
import 'package:sakasama/core/services/model_manager_service.dart';
import 'package:sakasama_vlm/sakasama_vlm.dart';

/// Hybrid offline OCR service that uses the custom `sakasama_vlm` native
/// MethodChannel plugin to run GOT-OCR 2.0.
///
/// **Pipeline:**
/// 1. Camera captures photo.
/// 2. Dart passes image path to Kotlin via MethodChannel.
/// 3. Kotlin executes LLaVA/clip Vision-Language Model via C++ JNI.
/// 4. Kotlin returns a JSON string containing the extracted properties.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  bool _isProcessing = false;

  // The native MethodChannel wrapper
  final _vlm = SakasamaVlm();

  /// Whether an inference is currently in progress.
  bool get isProcessing => _isProcessing;

  /// Name of the active OCR strategy (for UI display).
  String get activeStrategyName => 'GOT-OCR 2.0 (Native)';

  /// Whether the service has been initialized with a strategy.
  bool get isInitialized => true;

  /// Initialize: (Stub for VLM setup)
  Future<void> initialize({void Function(String status)? onStatus}) async {
    onStatus?.call('Handa na ang AI Vision Scanner.');
  }

  /// Run the full OCR pipeline natively by passing the image to C++.
  Future<OcrResult> processImage(String imagePath) async {
    if (_isProcessing) {
      throw StateError('May kasalukuyang OCR na ginagawa.');
    }

    _isProcessing = true;

    try {
      final basePath = await ModelManagerService.instance.getBaseModelPath();
      final visionPath = await ModelManagerService.instance
          .getVisionModelPath();

      if (basePath == null || visionPath == null) {
        final modelsDir = await ModelManagerService.instance
            .getModelsDirectory();
        throw StateError(
          "Hindi makita ang AI Models sa: $modelsDir. Mangyaring i-setup muna ito sa Onboarding screen.",
        );
      }

      final String prompt = '''
Suriin ang larawang ito ng isang produktong agrikultural (fertilizer, pesticide, herbicide, etc.).
Ibigay ang lahat ng impormasyong makikita sa format na JSON lamang, gamit ang mga sumusunod na keys:
{
  "product": "Pangalan ng produkto",
  "active_ingredient": "Aktibong sangkap o komposisyon",
  "dosage": "Inirerekomendang dami o paraan ng paggamit",
  "manufacturer": "Gumawa o brand",
  "net_weight": "Timbang o sukat (e.g., 50kg, 1L)",
  "expiry_date": "Petsa ng pag-expire",
  "registration_no": "FPA o registration number",
  "raw_text": "Iba pang mahahalagang text na nabasa mo"
}
Huwag maglagay ng kahit ano pang text maliban sa JSON block.
''';

      final String? jsonResponse = await _vlm.scanImageWithGotOcr(
        imagePath: imagePath,
        baseModelPath: basePath,
        visionModelPath: visionPath,
        prompt: prompt,
      );

      if (jsonResponse == null || jsonResponse.isEmpty) {
        throw Exception("Walang nakuhang sagot mula sa Native AI Scanner.");
      }

      return _parseJsonOutput(jsonResponse, imagePath: imagePath);
    } finally {
      _isProcessing = false;
    }
  }

  /// Parse raw LLM output into an [OcrResult].
  OcrResult _parseJsonOutput(String output, {String? imagePath}) {
    output = output.trim();
    print('OCR Native Raw Output: $output'); // Diagnostic log

    final firstBrace = output.indexOf('{');
    final lastBrace = output.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final jsonString = output.substring(firstBrace, lastBrace + 1);
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          // Explicitly check for internal native errors
          if (decoded.containsKey('error')) {
            throw Exception('Native OCR Error: ${decoded['error']}');
          }
          return OcrResult.fromJson(decoded, imagePath: imagePath);
        }
      } catch (e) {
        if (e is Exception) rethrow;
        // Fall back to raw text if JSON parsing fails
      }
    }

    return OcrResult.fromRawText(output, imagePath: imagePath);
  }
}
