import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/core/services/ocr_service.dart';
import 'package:sakasama/data/models/ocr_result.dart';

// ── OCR Service ───────────────────────────────────────────────────────

/// Singleton OCR service.
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService.instance;
});

/// State notifier for running an OCR inference.
final ocrInferenceProvider =
    StateNotifierProvider<OcrInferenceNotifier, OcrInferenceState>((ref) {
      return OcrInferenceNotifier(ref.watch(ocrServiceProvider));
    });

enum OcrStatus { idle, processing, done, error }

class OcrInferenceState {
  const OcrInferenceState({
    this.status = OcrStatus.idle,
    this.result,
    this.error,
  });

  final OcrStatus status;
  final OcrResult? result;
  final String? error;
}

class OcrInferenceNotifier extends StateNotifier<OcrInferenceState> {
  OcrInferenceNotifier(this._ocrService) : super(const OcrInferenceState());

  final OcrService _ocrService;

  /// Run OCR on an image using ML Kit + heuristic parsing.
  Future<void> processImage(String imagePath) async {
    try {
      state = const OcrInferenceState(status: OcrStatus.processing);
      final result = await _ocrService.processImage(imagePath);
      state = OcrInferenceState(status: OcrStatus.done, result: result);
    } catch (e) {
      state = OcrInferenceState(status: OcrStatus.error, error: e.toString());
    }
  }

  /// Reset to idle state.
  void reset() {
    state = const OcrInferenceState();
  }
}
