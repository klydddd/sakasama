/// Scan type detected by the OCR service.
enum ScanType { receipt, product, crop, unknown }

/// A single line item from a receipt.
class ReceiptLineItem {
  const ReceiptLineItem({
    this.description,
    this.quantity,
    this.unit,
    this.pricePerUnit,
    this.totalValue,
  });

  final String? description;
  final String? quantity;
  final String? unit;
  final String? pricePerUnit;
  final String? totalValue;

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      description: json['description']?.toString(),
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      pricePerUnit: json['price_per_unit']?.toString(),
      totalValue: json['total_value']?.toString(),
    );
  }

  ReceiptLineItem copyWith({
    String? description,
    String? quantity,
    String? unit,
    String? pricePerUnit,
    String? totalValue,
  }) {
    return ReceiptLineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalValue: totalValue ?? this.totalValue,
    );
  }
}

/// Structured result from OCR inference.
///
/// Supports three scan types: receipt (expense), product, and crop (harvest).
class OcrResult {
  const OcrResult({
    this.scanType = ScanType.unknown,
    // Common
    this.rawText,
    this.imagePath,
    this.confidence = const {},
    // Receipt / Expense
    this.date,
    this.description,
    this.quantity,
    this.unit,
    this.pricePerUnit,
    this.totalValue,
    this.supplier,
    this.lineItems = const [],
    // Product
    this.productName,
    this.productDescription,
    this.manufacturer,
    this.netWeight,
    this.expirationDate,
    this.category,
    // Crop / Harvest
    this.cropName,
    this.totalVolumeKg,
    this.institutionalVolumeKg,
    this.institutionalPricePhp,
    this.otherVolumeKg,
    this.otherPricePhp,
  });

  final ScanType scanType;

  // ── Common ─────────────────────────────────────────────────────
  final String? rawText;
  final String? imagePath;
  final Map<String, bool> confidence;

  // ── Receipt / Expense ──────────────────────────────────────────
  final String? date;
  final String? description;
  final String? quantity;
  final String? unit;
  final String? pricePerUnit;
  final String? totalValue;
  final String? supplier;
  final List<ReceiptLineItem> lineItems;

  /// Whether this receipt has multiple line items.
  bool get hasMultipleItems => lineItems.length > 1;

  // ── Product ────────────────────────────────────────────────────
  final String? productName;
  final String? productDescription;
  final String? manufacturer;
  final String? netWeight;
  final String? expirationDate;
  final String? category; // fertilizer, pesticide, seed, other

  // ── Crop / Harvest ─────────────────────────────────────────────
  final String? cropName;
  final String? totalVolumeKg;
  final String? institutionalVolumeKg;
  final String? institutionalPricePhp;
  final String? otherVolumeKg;
  final String? otherPricePhp;

  /// Whether a specific field was extracted with high confidence.
  bool isFieldConfident(String fieldKey) => confidence[fieldKey] ?? false;

  /// Parse from JSON map returned by Gemini.
  factory OcrResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final typeStr = (json['scan_type'] as String?)?.toLowerCase() ?? 'unknown';
    final scanType = switch (typeStr) {
      'receipt' => ScanType.receipt,
      'product' => ScanType.product,
      'crop' => ScanType.crop,
      _ => ScanType.unknown,
    };

    // Parse line items for receipts
    final List<ReceiptLineItem> lineItems = [];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is Map<String, dynamic>) {
          lineItems.add(ReceiptLineItem.fromJson(item));
        }
      }
    }

    // Fallback: if no items array but has description, create a single line item
    if (lineItems.isEmpty &&
        scanType == ScanType.receipt &&
        json['description'] != null) {
      lineItems.add(
        ReceiptLineItem(
          description: json['description']?.toString(),
          quantity: json['quantity']?.toString(),
          unit: json['unit']?.toString(),
          pricePerUnit: json['price_per_unit']?.toString(),
          totalValue: json['total_value']?.toString(),
        ),
      );
    }

    return OcrResult(
      scanType: scanType,
      imagePath: imagePath,
      rawText: json['raw_text'] as String?,
      // Receipt
      date: json['date']?.toString(),
      description: json['description']?.toString(),
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      pricePerUnit: json['price_per_unit']?.toString(),
      totalValue: json['total_value']?.toString(),
      supplier: json['supplier']?.toString(),
      lineItems: lineItems,
      // Product
      productName: json['product_name']?.toString(),
      productDescription: json['product_description']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      netWeight: json['net_weight']?.toString(),
      expirationDate: json['expiration_date']?.toString(),
      category: json['category']?.toString(),
      // Crop
      cropName: json['crop_name']?.toString(),
      totalVolumeKg: json['total_volume_kg']?.toString(),
      institutionalVolumeKg: json['institutional_volume_kg']?.toString(),
      institutionalPricePhp: json['institutional_price_php']?.toString(),
      otherVolumeKg: json['other_volume_kg']?.toString(),
      otherPricePhp: json['other_price_php']?.toString(),
      // Confidence: all present fields are confident from Gemini
      confidence: {
        for (final key in json.keys)
          if (json[key] != null && key != 'scan_type' && key != 'raw_text')
            key: true,
      },
    );
  }

  /// Create from raw text when parsing fails.
  factory OcrResult.fromRawText(String text, {String? imagePath}) {
    return OcrResult(rawText: text, imagePath: imagePath);
  }

  /// Whether any structured field was extracted.
  bool get hasStructuredData =>
      scanType != ScanType.unknown &&
      (description != null ||
          productName != null ||
          cropName != null ||
          date != null);

  /// Copy with overrides (for user edits on the review screen).
  OcrResult copyWith({
    ScanType? scanType,
    String? rawText,
    String? imagePath,
    Map<String, bool>? confidence,
    String? date,
    String? description,
    String? quantity,
    String? unit,
    String? pricePerUnit,
    String? totalValue,
    String? supplier,
    List<ReceiptLineItem>? lineItems,
    String? productName,
    String? productDescription,
    String? manufacturer,
    String? netWeight,
    String? expirationDate,
    String? category,
    String? cropName,
    String? totalVolumeKg,
    String? institutionalVolumeKg,
    String? institutionalPricePhp,
    String? otherVolumeKg,
    String? otherPricePhp,
  }) {
    return OcrResult(
      scanType: scanType ?? this.scanType,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      confidence: confidence ?? this.confidence,
      date: date ?? this.date,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalValue: totalValue ?? this.totalValue,
      supplier: supplier ?? this.supplier,
      lineItems: lineItems ?? this.lineItems,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      manufacturer: manufacturer ?? this.manufacturer,
      netWeight: netWeight ?? this.netWeight,
      expirationDate: expirationDate ?? this.expirationDate,
      category: category ?? this.category,
      cropName: cropName ?? this.cropName,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      institutionalVolumeKg:
          institutionalVolumeKg ?? this.institutionalVolumeKg,
      institutionalPricePhp:
          institutionalPricePhp ?? this.institutionalPricePhp,
      otherVolumeKg: otherVolumeKg ?? this.otherVolumeKg,
      otherPricePhp: otherPricePhp ?? this.otherPricePhp,
    );
  }
}
