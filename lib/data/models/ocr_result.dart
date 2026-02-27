/// Structured result from OCR inference on a product label
/// (fertilizers, pesticides, and other agricultural inputs).
class OcrResult {
  const OcrResult({
    this.product,
    this.activeIngredient,
    this.dosage,
    this.manufacturer,
    this.netWeight,
    this.expiryDate,
    this.registrationNo,
    this.rawText,
    this.imagePath,
    this.confidence = const {},
  });

  /// Product name (e.g., "Complete Fertilizer 14-14-14").
  final String? product;

  /// Active ingredient or composition (e.g., "Nitrogen 14%, Phosphorus 14%").
  final String? activeIngredient;

  /// Recommended dosage or application rate (e.g., "4-6 bags/hectare").
  final String? dosage;

  /// Manufacturer or brand (e.g., "Atlas Fertilizer Corporation").
  final String? manufacturer;

  /// Net weight or volume (e.g., "50 kg", "1 L").
  final String? netWeight;

  /// Expiry date or manufacturing date.
  final String? expiryDate;

  /// Government registration number (e.g., FPA registration).
  final String? registrationNo;

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
      activeIngredient: json['active_ingredient'] as String?,
      dosage: json['dosage'] as String?,
      manufacturer: json['manufacturer'] as String?,
      netWeight: json['net_weight'] as String?,
      expiryDate: json['expiry_date'] as String?,
      registrationNo: json['registration_no'] as String?,
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
    'active_ingredient': activeIngredient,
    'dosage': dosage,
    'manufacturer': manufacturer,
    'net_weight': netWeight,
    'expiry_date': expiryDate,
    'registration_no': registrationNo,
    'raw_text': rawText,
  };

  /// Whether any structured field was extracted.
  bool get hasStructuredData =>
      product != null ||
      activeIngredient != null ||
      dosage != null ||
      manufacturer != null ||
      netWeight != null ||
      expiryDate != null ||
      registrationNo != null;

  /// Copy with overrides (for user edits on the review screen).
  OcrResult copyWith({
    String? product,
    String? activeIngredient,
    String? dosage,
    String? manufacturer,
    String? netWeight,
    String? expiryDate,
    String? registrationNo,
    String? rawText,
    String? imagePath,
    Map<String, bool>? confidence,
  }) {
    return OcrResult(
      product: product ?? this.product,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      dosage: dosage ?? this.dosage,
      manufacturer: manufacturer ?? this.manufacturer,
      netWeight: netWeight ?? this.netWeight,
      expiryDate: expiryDate ?? this.expiryDate,
      registrationNo: registrationNo ?? this.registrationNo,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      confidence: confidence ?? this.confidence,
    );
  }
}
