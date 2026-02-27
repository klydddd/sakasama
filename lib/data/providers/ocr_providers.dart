import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/core/services/ocr_service.dart';
import 'package:sakasama/data/models/ocr_result.dart';

// ── OCR Service ───────────────────────────────────────────────────────

/// Singleton OCR service.
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService.instance;
  ref.onDispose(() => service.dispose());
  return service;
});

// ── OCR Strategy Initialization ───────────────────────────────────────

/// State notifier for OCR strategy initialization.
final ocrInitProvider = StateNotifierProvider<OcrInitNotifier, OcrInitState>((
  ref,
) {
  return OcrInitNotifier(ref.watch(ocrServiceProvider));
});

enum OcrInitStatus { notReady, initializing, ready, error }

class OcrInitState {
  const OcrInitState({
    this.status = OcrInitStatus.notReady,
    this.statusMessage = '',
    this.activeStrategy = '',
    this.error,
  });

  final OcrInitStatus status;
  final String statusMessage;
  final String activeStrategy;
  final String? error;
}

class OcrInitNotifier extends StateNotifier<OcrInitState> {
  OcrInitNotifier(this._service) : super(const OcrInitState());

  final OcrService _service;

  /// Initialize OCR strategies — detects Gemini Nano, falls back to GGUF.
  Future<void> initialize() async {
    if (state.status == OcrInitStatus.ready) return;

    state = const OcrInitState(
      status: OcrInitStatus.initializing,
      statusMessage: 'Sinusuri ang OCR strategies...',
    );

    try {
      await _service.initialize(
        onStatus: (msg) {
          state = OcrInitState(
            status: OcrInitStatus.initializing,
            statusMessage: msg,
          );
        },
      );

      state = OcrInitState(
        status: OcrInitStatus.ready,
        statusMessage: 'Handa na!',
        activeStrategy: _service.activeStrategyName,
      );
    } catch (e) {
      state = OcrInitState(
        status: OcrInitStatus.error,
        error: e.toString(),
        statusMessage: 'May error sa pag-setup ng OCR.',
      );
    }
  }
}

// ── OCR Inference ─────────────────────────────────────────────────────

/// State notifier for running an OCR inference.
final ocrInferenceProvider =
    StateNotifierProvider<OcrInferenceNotifier, OcrInferenceState>((ref) {
      return OcrInferenceNotifier(ref.watch(ocrServiceProvider));
    });

enum OcrStatus { idle, initializing, processing, done, error }

class OcrInferenceState {
  const OcrInferenceState({
    this.status = OcrStatus.idle,
    this.result,
    this.error,
    this.activeStrategy,
  });

  final OcrStatus status;
  final OcrResult? result;
  final String? error;
  final String? activeStrategy;
}

class OcrInferenceNotifier extends StateNotifier<OcrInferenceState> {
  OcrInferenceNotifier(this._ocrService) : super(const OcrInferenceState());

  final OcrService _ocrService;

  /// Run OCR on an image. Initializes strategy if not yet done.
  Future<void> processImage(String imagePath) async {
    try {
      // Initialize strategies if needed
      if (!_ocrService.isInitialized) {
        state = const OcrInferenceState(status: OcrStatus.initializing);
        await _ocrService.initialize();
      }

      // Run inference
      state = OcrInferenceState(
        status: OcrStatus.processing,
        activeStrategy: _ocrService.activeStrategyName,
      );

      final result = await _ocrService.processImage(imagePath);

      state = OcrInferenceState(
        status: OcrStatus.done,
        result: result,
        activeStrategy: _ocrService.activeStrategyName,
      );
    } catch (e) {
      state = OcrInferenceState(status: OcrStatus.error, error: e.toString());
    }
  }

  /// Reset to idle state.
  void reset() {
    state = const OcrInferenceState();
  }
}
