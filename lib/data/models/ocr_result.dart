/// Structured result from OCR inference.
class OcrResult {
  const OcrResult({
    this.product,
    this.price,
    this.quantity,
    this.supplier,
    this.date,
    this.rawText,
    this.imagePath,
    this.confidence = const {},
  });

  /// Product name extracted from the image.
  final String? product;

  /// Price with currency.
  final String? price;

  /// Quantity with unit.
  final String? quantity;

  /// Supplier or store name.
  final String? supplier;

  /// Date found on the receipt/label.
  final String? date;

  /// All raw text extracted from the image.
  final String? rawText;

  /// Path to the source image.
  final String? imagePath;

  /// Per-field confidence: `true` = high (regex match), `false` = low (guess).
  final Map<String, bool> confidence;

  /// Whether a specific field was extracted with high confidence.
  bool isFieldConfident(String fieldKey) => confidence[fieldKey] ?? false;

  /// Parse from JSON map.
  factory OcrResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final rawConfidence = json['confidence'];
    final confidenceMap = rawConfidence is Map
        ? Map<String, bool>.from(
            rawConfidence.map((k, v) => MapEntry(k.toString(), v == true)),
          )
        : <String, bool>{};

    return OcrResult(
      product: json['product'] as String?,
      price: json['price'] as String?,
      quantity: json['quantity'] as String?,
      supplier: json['supplier'] as String?,
      date: json['date'] as String?,
      rawText: json['raw_text'] as String?,
      imagePath: imagePath,
      confidence: confidenceMap,
    );
  }

  /// Create from raw text when parsing fails.
  factory OcrResult.fromRawText(String text, {String? imagePath}) {
    return OcrResult(rawText: text, imagePath: imagePath);
  }

  /// Convert to map for saving to DB.
  Map<String, dynamic> toJson() => {
    'product': product,
    'price': price,
    'quantity': quantity,
    'supplier': supplier,
    'date': date,
    'raw_text': rawText,
  };

  /// Whether any structured field was extracted.
  bool get hasStructuredData =>
      product != null ||
      price != null ||
      quantity != null ||
      supplier != null ||
      date != null;

  /// Copy with overrides (for user edits on the review screen).
  OcrResult copyWith({
    String? product,
    String? price,
    String? quantity,
    String? supplier,
    String? date,
    String? rawText,
    String? imagePath,
    Map<String, bool>? confidence,
  }) {
    return OcrResult(
      product: product ?? this.product,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      supplier: supplier ?? this.supplier,
      date: date ?? this.date,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      confidence: confidence ?? this.confidence,
    );
  }
}
