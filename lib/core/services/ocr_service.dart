import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sakasama/core/services/receipt_parser.dart';
import 'package:sakasama/data/models/ocr_result.dart';

/// Offline OCR service using ML Kit text recognition + heuristic parsing.
///
/// **Stage 1** — Google ML Kit: extracts text blocks with bounding boxes.
/// **Stage 2** — [ReceiptParser]: uses spatial layout + regex to identify
///   structured fields (product, price, quantity, supplier, date).
///
/// No LLM or internet connection required.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  bool _isProcessing = false;

  /// Whether an inference is currently in progress.
  bool get isProcessing => _isProcessing;

  /// Run the OCR pipeline on an image file.
  ///
  /// 1. ML Kit extracts text blocks with bounding boxes.
  /// 2. [ReceiptParser] uses heuristics to identify fields.
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

      // ── Stage 2: Heuristic field extraction ───────────────────────
      final parsed = ReceiptParser.parse(recognizedText);
      final confidenceMap = parsed['confidence'] as Map<String, bool>? ?? {};

      return OcrResult(
        product: parsed['product'] as String?,
        price: parsed['price'] as String?,
        quantity: parsed['quantity'] as String?,
        supplier: parsed['supplier'] as String?,
        date: parsed['date'] as String?,
        rawText: parsed['raw_text'] as String?,
        imagePath: imagePath,
        confidence: Map<String, bool>.from(confidenceMap),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Extract text from image using Google ML Kit.
  ///
  /// Returns the full [RecognizedText] object (not just `.text`) so we
  /// can access block/line bounding boxes for spatial parsing.
  Future<RecognizedText> _recognizeText(String imagePath) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await textRecognizer.processImage(inputImage);
    } finally {
      textRecognizer.close();
    }
  }
}
