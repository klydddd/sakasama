import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Heuristic receipt parser that uses ML Kit's block-level text recognition
/// (with bounding boxes) to extract structured fields from receipts.
///
/// Instead of passing flat text to an LLM, this uses spatial layout + regex
/// patterns to identify: date, supplier, product names, prices, and quantities.
class ReceiptParser {
  ReceiptParser._();

  // ── Date patterns ────────────────────────────────────────────────────
  static final List<RegExp> _datePatterns = [
    // DD/MM/YYYY or DD-MM-YYYY
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
    // YYYY-MM-DD or YYYY/MM/DD
    RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    // Month DD, YYYY (e.g., "December 23, 2022")
    RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s*(\d{4})',
      caseSensitive: false,
    ),
    // DD Month YYYY (e.g., "23 December 2022")
    RegExp(
      r'(\d{1,2})\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})',
      caseSensitive: false,
    ),
  ];

  // ── Price patterns ───────────────────────────────────────────────────
  static final RegExp _pricePattern = RegExp(
    r'(\d{1,3}(?:[,]\d{3})*(?:\.\d{1,2})?)\s*(?:PHP|Php|php|₱|pesos?)',
    caseSensitive: false,
  );

  static final RegExp _pricePatternAlt = RegExp(
    r'(?:PHP|Php|php|₱)\s*(\d{1,3}(?:[,]\d{3})*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // ── Quantity patterns ────────────────────────────────────────────────
  static final RegExp _quantityPattern = RegExp(
    r'(\d+)\s*(?:pcs?|pieces?|units?|kg|kgs?|g|lbs?|liters?|L|ml|gal|doz|dozen|boxes?|packs?|bags?|bundles?|rolls?|bottles?|cans?|sacks?)',
    caseSensitive: false,
  );

  // ── Section header keywords ──────────────────────────────────────────
  static final RegExp _itemHeaderPattern = RegExp(
    r'item\s*list|items?|description|product|particulars|pangalan',
    caseSensitive: false,
  );

  static final RegExp _totalPattern = RegExp(
    r'\b(?:total|sub\s*total|grand\s*total|all|kabuuan|lahat)\b',
    caseSensitive: false,
  );

  static final RegExp _skipLinePattern = RegExp(
    r'(?:receipt|invoice|order|store\s*details?|customer\s*details?|shipping|contact|email|phone|address|view\s*more|paid\s*by|payment|note|thank\s*you|discount|shipping|VAT|vat|tax)',
    caseSensitive: false,
  );

  static final RegExp _dateLabel = RegExp(r'\bdate\b', caseSensitive: false);

  /// Parse [RecognizedText] from ML Kit into structured receipt fields.
  ///
  /// Returns a map with keys: `product`, `price`, `quantity`, `supplier`,
  /// `date`, `raw_text`, and `confidence` (a nested map of field → bool).
  static Map<String, dynamic> parse(RecognizedText recognized) {
    final allText = recognized.text;
    final blocks = recognized.blocks;

    if (blocks.isEmpty) {
      return {'raw_text': allText};
    }

    // Sort blocks top-to-bottom by their bounding box Y coordinate
    final sortedBlocks = List<TextBlock>.from(blocks)
      ..sort((a, b) {
        final ay = a.boundingBox.top;
        final by = b.boundingBox.top;
        return ay.compareTo(by);
      });

    // Flatten to annotated lines with Y position
    final annotatedLines = <_AnnotatedLine>[];
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        annotatedLines.add(
          _AnnotatedLine(
            text: line.text,
            top: line.boundingBox.top,
            left: line.boundingBox.left,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
          ),
        );
      }
    }

    // Sort annotated lines top-to-bottom
    annotatedLines.sort((a, b) => a.top.compareTo(b.top));

    // ── Extract fields ─────────────────────────────────────────────────
    final date = _extractDate(annotatedLines);
    final supplier = _extractSupplier(annotatedLines);
    final products = _extractProducts(annotatedLines);
    final priceInfo = _extractPrices(annotatedLines);
    final quantity = _extractQuantity(annotatedLines);

    // Build confidence map
    final confidence = <String, bool>{
      'date': date != null,
      'supplier': supplier != null,
      'product': products != null,
      'price': priceInfo != null,
      'quantity': quantity != null,
    };

    return {
      'date': date,
      'supplier': supplier,
      'product': products,
      'price': priceInfo,
      'quantity': quantity,
      'raw_text': allText,
      'confidence': confidence,
    };
  }

  /// Extract date from the receipt text.
  ///
  /// Strategy: Look for lines containing "Date" label first, then scan all
  /// lines for date patterns. Normalize to YYYY-MM-DD format.
  static String? _extractDate(List<_AnnotatedLine> lines) {
    // First, look for lines with "Date" label
    for (final line in lines) {
      if (_dateLabel.hasMatch(line.text)) {
        final dateStr = _findDateInText(line.text);
        if (dateStr != null) return dateStr;
      }
    }

    // Then scan all lines for date patterns
    for (final line in lines) {
      final dateStr = _findDateInText(line.text);
      if (dateStr != null) return dateStr;
    }

    return null;
  }

  /// Find and normalize a date string within text.
  static String? _findDateInText(String text) {
    // DD/MM/YYYY or DD-MM-YYYY
    final m1 = _datePatterns[0].firstMatch(text);
    if (m1 != null) {
      final day = m1.group(1)!.padLeft(2, '0');
      final month = m1.group(2)!.padLeft(2, '0');
      final year = m1.group(3)!;
      return '$year-$month-$day';
    }

    // YYYY-MM-DD or YYYY/MM/DD
    final m2 = _datePatterns[1].firstMatch(text);
    if (m2 != null) {
      final year = m2.group(1)!;
      final month = m2.group(2)!.padLeft(2, '0');
      final day = m2.group(3)!.padLeft(2, '0');
      return '$year-$month-$day';
    }

    // Month DD, YYYY
    final m3 = _datePatterns[2].firstMatch(text);
    if (m3 != null) {
      final monthName = m3.group(1)!;
      final day = m3.group(2)!.padLeft(2, '0');
      final year = m3.group(3)!;
      final month = _monthNumber(monthName);
      return '$year-$month-$day';
    }

    // DD Month YYYY
    final m4 = _datePatterns[3].firstMatch(text);
    if (m4 != null) {
      final day = m4.group(1)!.padLeft(2, '0');
      final monthName = m4.group(2)!;
      final year = m4.group(3)!;
      final month = _monthNumber(monthName);
      return '$year-$month-$day';
    }

    return null;
  }

  /// Convert month name to zero-padded number string.
  static String _monthNumber(String name) {
    const months = {
      'january': '01',
      'february': '02',
      'march': '03',
      'april': '04',
      'may': '05',
      'june': '06',
      'july': '07',
      'august': '08',
      'september': '09',
      'october': '10',
      'november': '11',
      'december': '12',
    };
    return months[name.toLowerCase()] ?? '01';
  }

  /// Extract supplier/store name from receipt.
  ///
  /// Strategy: The store name is typically one of the first non-header text
  /// blocks at the top of the receipt. Skip common headers like "Receipt",
  /// "Invoice", receipt numbers, etc.
  static String? _extractSupplier(List<_AnnotatedLine> lines) {
    final skipWords = RegExp(
      r'^(receipt|invoice|order|#\d+|no\.?\s*\d+|\d+)$',
      caseSensitive: false,
    );

    final storeDetailsLabel = RegExp(
      r'store\s*details?|supplier|vendor|sold\s*by|from',
      caseSensitive: false,
    );

    // Look for a "Store details" label and take the next line
    for (int i = 0; i < lines.length; i++) {
      if (storeDetailsLabel.hasMatch(lines[i].text)) {
        // Take the next non-empty line as the supplier
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final candidate = lines[j].text.trim();
          if (candidate.isNotEmpty &&
              !skipWords.hasMatch(candidate) &&
              !_dateLabel.hasMatch(candidate) &&
              !_pricePattern.hasMatch(candidate)) {
            return candidate;
          }
        }
      }
    }

    // Fallback: take the first non-header, non-empty line from the top
    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;
      if (skipWords.hasMatch(text)) continue;
      if (text.length < 3) continue; // Too short to be a store name

      // Skip lines that are clearly dates, prices, or section headers
      if (_dateLabel.hasMatch(text)) continue;
      if (_pricePattern.hasMatch(text)) continue;
      if (_pricePatternAlt.hasMatch(text)) continue;
      if (RegExp(
        r'^(receipt|invoice|order)\b',
        caseSensitive: false,
      ).hasMatch(text)) {
        continue;
      }
      if (RegExp(r'^#?\d+$').hasMatch(text)) continue;
      if (RegExp(
        r'^(store|customer)\s+details?$',
        caseSensitive: false,
      ).hasMatch(text)) {
        continue;
      }

      return text;
    }

    return null;
  }

  /// Extract product names from the receipt.
  ///
  /// Strategy: Find the item list section (between "Item list" header and
  /// "Total"/"All" row), then collect product name lines. If no clear section
  /// markers, fall back to lines that don't look like prices/dates/headers.
  static String? _extractProducts(List<_AnnotatedLine> lines) {
    int itemStart = -1;
    int itemEnd = lines.length;

    // Find section boundaries
    for (int i = 0; i < lines.length; i++) {
      if (_itemHeaderPattern.hasMatch(lines[i].text) && itemStart == -1) {
        itemStart = i + 1; // Start after the header
      }
      if (_totalPattern.hasMatch(lines[i].text) && itemStart != -1) {
        itemEnd = i;
        break;
      }
    }

    // If we found a clear item section
    if (itemStart != -1) {
      final products = <String>[];
      for (int i = itemStart; i < itemEnd; i++) {
        final text = lines[i].text.trim();
        if (text.isEmpty) continue;

        // Skip pure number lines (quantities, prices columns)
        if (RegExp(
          r'^\d+\.?\d*\s*(PHP|₱|Php)?$',
          caseSensitive: false,
        ).hasMatch(text)) {
          continue;
        }

        // Skip standalone numbers (like "1", "2", "3" for row numbers)
        if (RegExp(r'^\d+\.?$').hasMatch(text)) continue;

        // Skip lines that are only prices
        if (_pricePattern.hasMatch(text) &&
            _pricePattern.firstMatch(text)!.group(0)!.length >
                text.length * 0.7) {
          continue;
        }

        // This looks like a product name
        // Remove leading row number (e.g., "1. " or "1 ")
        final cleaned = text.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty && cleaned.length > 2) {
          products.add(cleaned);
        }
      }

      if (products.isNotEmpty) {
        return products.join(', ');
      }
    }

    // Fallback: look for lines that aren't headers, dates, prices, or addresses
    final candidates = <String>[];
    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty || text.length < 4) continue;
      if (_skipLinePattern.hasMatch(text)) continue;
      if (_dateLabel.hasMatch(text)) continue;
      if (_totalPattern.hasMatch(text)) continue;

      // Skip lines that are mostly numbers/prices
      if (RegExp(r'^\d').hasMatch(text) &&
          RegExp(r'PHP|₱|Php', caseSensitive: false).hasMatch(text)) {
        continue;
      }

      // Skip obvious addresses (contain city/province names or zip codes)
      if (RegExp(r'\d{4,5}').hasMatch(text) &&
          RegExp(
            r'city|province|manila|metro|jaro|iloilo',
            caseSensitive: false,
          ).hasMatch(text)) {
        continue;
      }

      // Skip contact info
      if (RegExp(r'@|\.com|\.net|\.ph|\+\d{10,}').hasMatch(text)) continue;

      // Check if it contains product-like words
      if (_containsProductIndicators(text)) {
        final cleaned = text.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          candidates.add(cleaned);
        }
      }
    }

    return candidates.isNotEmpty ? candidates.join(', ') : null;
  }

  /// Check if text looks like a product name/description.
  static bool _containsProductIndicators(String text) {
    // Product names typically have letters and are descriptive
    // They're NOT pure numbers, dates, or contact info
    if (RegExp(r'^[\d\s.,₱]+$').hasMatch(text)) return false;
    if (text.contains('@')) return false;
    if (RegExp(
      r'^\+?\d{7,}$',
    ).hasMatch(text.replaceAll(RegExp(r'[\s\-]'), ''))) {
      return false;
    }

    // Has at least some alphabetic content and reasonable length
    final alphaCount = RegExp(r'[a-zA-Z]').allMatches(text).length;
    return alphaCount >= 3 && text.length >= 4;
  }

  /// Extract prices from the receipt.
  ///
  /// Strategy: Find all price-like strings (numbers followed by PHP/₱),
  /// then determine which is the relevant "unit price" or "total".
  /// Returns the first individual item price found (not the grand total).
  static String? _extractPrices(List<_AnnotatedLine> lines) {
    final prices = <_PriceMatch>[];

    for (int i = 0; i < lines.length; i++) {
      final text = lines[i].text;

      // Check if this line is in the "total" section
      final isTotal = _totalPattern.hasMatch(text);

      // Find prices in this line
      for (final pattern in [_pricePattern, _pricePatternAlt]) {
        for (final match in pattern.allMatches(text)) {
          final amountStr = match.group(1) ?? '';
          if (amountStr.isEmpty) continue;

          final amount = double.tryParse(amountStr.replaceAll(',', ''));
          if (amount == null || amount <= 0) continue;

          prices.add(
            _PriceMatch(
              amount: amount,
              formatted: '${amount.toStringAsFixed(2)} PHP',
              lineIndex: i,
              isTotal: isTotal,
              top: lines[i].top,
            ),
          );
        }
      }
    }

    if (prices.isEmpty) return null;

    // Separate total prices from item prices
    final itemPrices = prices.where((p) => !p.isTotal).toList();
    final totalPrices = prices.where((p) => p.isTotal).toList();

    // Return the first item price (typically "Price per unit" of first item)
    if (itemPrices.isNotEmpty) {
      // Sort by vertical position, take the first one
      itemPrices.sort((a, b) => a.top.compareTo(b.top));
      return itemPrices.first.formatted;
    }

    // Fallback: return smallest total price
    if (totalPrices.isNotEmpty) {
      totalPrices.sort((a, b) => a.amount.compareTo(b.amount));
      return totalPrices.first.formatted;
    }

    return null;
  }

  /// Extract quantity from the receipt.
  ///
  /// Strategy: Look for explicit quantity patterns (e.g., "3 pcs"),
  /// or look for the "Amount" column values in the item section.
  static String? _extractQuantity(List<_AnnotatedLine> lines) {
    // First, look for explicit quantity patterns
    for (final line in lines) {
      final match = _quantityPattern.firstMatch(line.text);
      if (match != null) {
        return match.group(0);
      }
    }

    // Look for "Amount" column header and get values below it
    final amountHeader = RegExp(
      r'\b(?:amount|qty|quantity|dami|bilang)\b',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      if (amountHeader.hasMatch(lines[i].text)) {
        // Look for integer values in subsequent lines at similar X position
        final headerLeft = lines[i].left;
        final headerRight = lines[i].right;

        for (int j = i + 1; j < lines.length; j++) {
          if (_totalPattern.hasMatch(lines[j].text)) break;

          final text = lines[j].text.trim();
          // Check if it's a standalone integer (quantity value)
          if (RegExp(r'^\d+$').hasMatch(text)) {
            // Check X-position proximity to header
            final lineCenter = (lines[j].left + lines[j].right) / 2;
            final headerCenter = (headerLeft + headerRight) / 2;
            if ((lineCenter - headerCenter).abs() < 100) {
              return text;
            }
          }
        }
      }
    }

    return null;
  }
}

/// Internal helper: annotated text line with position data.
class _AnnotatedLine {
  const _AnnotatedLine({
    required this.text,
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double top;
  final double left;
  final double right;
  final double bottom;
}

/// Internal helper: a detected price with metadata.
class _PriceMatch {
  const _PriceMatch({
    required this.amount,
    required this.formatted,
    required this.lineIndex,
    required this.isTotal,
    required this.top,
  });

  final double amount;
  final String formatted;
  final int lineIndex;
  final bool isTotal;
  final double top;
}
