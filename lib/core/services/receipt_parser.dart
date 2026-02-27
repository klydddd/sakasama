import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Heuristic product label parser that uses ML Kit's block-level text
/// recognition (with bounding boxes) to extract structured fields from
/// agricultural product labels (fertilizers, pesticides, etc.).
///
/// This is the **last-resort fallback** when both Gemini Nano and GGUF
/// strategies are unavailable. It uses regex patterns + spatial layout.
class ReceiptParser {
  ReceiptParser._();

  // ── Date patterns ────────────────────────────────────────────────────
  static final List<RegExp> _datePatterns = [
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
    RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s*(\d{4})',
      caseSensitive: false,
    ),
    RegExp(
      r'(\d{1,2})\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})',
      caseSensitive: false,
    ),
  ];

  // ── Weight / Volume patterns ──────────────────────────────────────────
  static final RegExp _weightPattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*(kg|g|lbs?|lb|oz|ml|mL|L|liters?|litro|gallons?|cc)',
    caseSensitive: false,
  );

  static final RegExp _netWeightLabel = RegExp(
    r'net\s*(?:weight|wt|content)|laman|nilalaman|timbang',
    caseSensitive: false,
  );

  // ── Registration patterns ─────────────────────────────────────────────
  static final RegExp _registrationPattern = RegExp(
    r'(?:FPA|EPA|reg(?:istration)?\.?\s*(?:no|number|#)?\.?\s*[:.]?\s*)(\S[\w\-/]+)',
    caseSensitive: false,
  );

  // ── Expiry patterns ───────────────────────────────────────────────────
  static final RegExp _expiryLabel = RegExp(
    r'(?:exp(?:iry|iration)?\.?\s*(?:date)?|best\s*before|mfg\.?\s*(?:date)?|mfr\.?\s*date|manufacturing\s*date)',
    caseSensitive: false,
  );

  // ── Active ingredient patterns ────────────────────────────────────────
  static final RegExp _ingredientLabel = RegExp(
    r'(?:active\s*ingredient|a\.?i\.?|composition|sangkap|lamang?\s*aktibo|guaranteed\s*analysis)',
    caseSensitive: false,
  );

  static final RegExp _concentrationPattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*(%|g/L|mg/L|ppm|w/v|w/w)',
    caseSensitive: false,
  );

  // ── Dosage patterns ───────────────────────────────────────────────────
  static final RegExp _dosageLabel = RegExp(
    r'(?:dosage|application\s*rate|rate\s*of\s*application|dosis|takaran|recommended\s*rate|directions?\s*for\s*use|paraan\s*ng\s*paggamit)',
    caseSensitive: false,
  );

  // ── Manufacturer patterns ─────────────────────────────────────────────
  static final RegExp _manufacturerLabel = RegExp(
    r'(?:manufactured?\s*by|mfr|mfg\s*by|distributed\s*by|marketed\s*by|gawa\s*ng|company|corporation|corp\.?|inc\.?|ltd\.?)',
    caseSensitive: false,
  );

  // ── Skip patterns ────────────────────────────────────────────────────
  static final RegExp _skipPattern = RegExp(
    r'(?:warning|caution|keep\s*out|precaution|first\s*aid|antidote|storage|disposal|peligro|babala)',
    caseSensitive: false,
  );

  /// Parse [RecognizedText] from ML Kit into structured product label fields.
  ///
  /// Returns a map with keys: `product`, `active_ingredient`, `dosage`,
  /// `manufacturer`, `net_weight`, `expiry_date`, `registration_no`,
  /// `raw_text`, and `confidence`.
  static Map<String, dynamic> parse(RecognizedText recognized) {
    final allText = recognized.text;
    final blocks = recognized.blocks;

    if (blocks.isEmpty) {
      return {'raw_text': allText};
    }

    // Sort blocks top-to-bottom
    final sortedBlocks = List<TextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Flatten to annotated lines
    final lines = <_AnnotatedLine>[];
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        lines.add(
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

    lines.sort((a, b) => a.top.compareTo(b.top));

    // ── Extract fields ─────────────────────────────────────────────────
    final product = _extractProductName(lines);
    final activeIngredient = _extractActiveIngredient(lines);
    final dosage = _extractDosage(lines);
    final manufacturer = _extractManufacturer(lines);
    final netWeight = _extractNetWeight(lines);
    final expiryDate = _extractExpiryDate(lines);
    final registrationNo = _extractRegistrationNo(lines);

    final confidence = <String, bool>{
      'product': product != null,
      'activeIngredient': activeIngredient != null,
      'dosage': dosage != null,
      'manufacturer': manufacturer != null,
      'netWeight': netWeight != null,
      'expiryDate': expiryDate != null,
      'registrationNo': registrationNo != null,
    };

    return {
      'product': product,
      'active_ingredient': activeIngredient,
      'dosage': dosage,
      'manufacturer': manufacturer,
      'net_weight': netWeight,
      'expiry_date': expiryDate,
      'registration_no': registrationNo,
      'raw_text': allText,
      'confidence': confidence,
    };
  }

  /// Extract product name — typically the largest or topmost prominent text.
  /// Made robust against skewed/poorly framed photos by finding the largest
  /// text anywhere on the label, rather than assuming it's in the top 50%.
  static String? _extractProductName(List<_AnnotatedLine> lines) {
    if (lines.isEmpty) return null;

    final candidates = <_AnnotatedLine>[];

    // Skip very short lines, pure numbers, and marketing text
    for (final line in lines) {
      final text = line.text.trim();
      if (text.length < 3) continue;
      // Allow NPK formats like 16-20-0 but skip raw number rows like "1", "45.0"
      if (RegExp(r'^[\d\s.,]+$').hasMatch(text)) continue;
      if (_skipPattern.hasMatch(text)) continue;
      if (_manufacturerLabel.hasMatch(text)) continue;
      if (_registrationPattern.hasMatch(text)) continue;

      // Skip common marketing text that ML Kit might misread as the biggest item
      if (RegExp(
        r'trusted\s*for|years|since|new|improved|quality|best',
        caseSensitive: false,
      ).hasMatch(text)) {
        continue;
      }

      candidates.add(line);
    }

    if (candidates.isEmpty) return null;

    // Find the largest text blocks by bounding box height
    candidates.sort((a, b) {
      final hA = a.bottom - a.top;
      final hB = b.bottom - b.top;
      return hB.compareTo(hA); // Descending
    });

    final largest = candidates.first;
    final largestHeight = largest.bottom - largest.top;
    final largestCenterY = (largest.top + largest.bottom) / 2;

    // To handle augmentations (skew, imperfect framing), gather text blocks
    // that are prominently large (at least 45% of largest text) AND are
    // physically located near the largest text.
    final titleParts = candidates.where((l) {
      final h = l.bottom - l.top;
      if (h < largestHeight * 0.45) return false;

      // Must be near the main title vertically (within 4x the height)
      final lCenterY = (l.top + l.bottom) / 2;
      return (lCenterY - largestCenterY).abs() < (largestHeight * 4.0);
    }).toList();

    // Sort them back to reading order (top to bottom)
    titleParts.sort((a, b) => a.top.compareTo(b.top));

    return titleParts.map((l) => l.text.trim()).join(' ');
  }

  /// Extract active ingredient(s).
  static String? _extractActiveIngredient(List<_AnnotatedLine> lines) {
    // Look for "Active Ingredient" label and take subsequent text
    for (int i = 0; i < lines.length; i++) {
      if (_ingredientLabel.hasMatch(lines[i].text)) {
        // Check same line for content after the label
        final afterLabel = lines[i].text
            .replaceFirst(_ingredientLabel, '')
            .replaceFirst(RegExp(r'^[\s:]+'), '')
            .trim();
        if (afterLabel.isNotEmpty) return afterLabel;

        // Take the next 1-3 lines as ingredient content
        final parts = <String>[];
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final text = lines[j].text.trim();
          if (text.isEmpty) continue;
          if (_dosageLabel.hasMatch(text)) break;
          if (_manufacturerLabel.hasMatch(text)) break;
          if (_skipPattern.hasMatch(text)) break;
          parts.add(text);
        }
        if (parts.isNotEmpty) return parts.join(', ');
      }
    }

    // Fallback: look for concentration patterns (e.g., "14% N")
    for (final line in lines) {
      if (_concentrationPattern.hasMatch(line.text)) {
        return line.text.trim();
      }
    }

    return null;
  }

  /// Extract dosage / application rate.
  static String? _extractDosage(List<_AnnotatedLine> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (_dosageLabel.hasMatch(lines[i].text)) {
        final afterLabel = lines[i].text
            .replaceFirst(_dosageLabel, '')
            .replaceFirst(RegExp(r'^[\s:]+'), '')
            .trim();
        if (afterLabel.isNotEmpty) return afterLabel;

        final parts = <String>[];
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final text = lines[j].text.trim();
          if (text.isEmpty) continue;
          if (_manufacturerLabel.hasMatch(text)) break;
          if (_skipPattern.hasMatch(text)) break;
          parts.add(text);
        }
        if (parts.isNotEmpty) return parts.join(' ');
      }
    }

    return null;
  }

  /// Extract manufacturer / brand name.
  static String? _extractManufacturer(List<_AnnotatedLine> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (_manufacturerLabel.hasMatch(lines[i].text)) {
        // Check if the manufacturer name is on the same line
        final afterLabel = lines[i].text
            .replaceFirst(_manufacturerLabel, '')
            .replaceFirst(RegExp(r'^[\s:]+'), '')
            .trim();
        if (afterLabel.isNotEmpty && afterLabel.length > 2) return afterLabel;

        // Otherwise take the next line
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final text = lines[j].text.trim();
          if (text.isNotEmpty && text.length > 2) return text;
        }
      }
    }

    return null;
  }

  /// Extract net weight or volume.
  static String? _extractNetWeight(List<_AnnotatedLine> lines) {
    // Look for "Net Weight" label first
    for (int i = 0; i < lines.length; i++) {
      if (_netWeightLabel.hasMatch(lines[i].text)) {
        final match = _weightPattern.firstMatch(lines[i].text);
        if (match != null) return match.group(0);

        // Check next line
        if (i + 1 < lines.length) {
          final nextMatch = _weightPattern.firstMatch(lines[i + 1].text);
          if (nextMatch != null) return nextMatch.group(0);
        }
      }
    }

    // Scan all lines for weight patterns
    for (final line in lines) {
      final match = _weightPattern.firstMatch(line.text);
      if (match != null) return match.group(0);
    }

    return null;
  }

  /// Extract expiry or manufacturing date.
  static String? _extractExpiryDate(List<_AnnotatedLine> lines) {
    // Look for expiry/mfg label first
    for (final line in lines) {
      if (_expiryLabel.hasMatch(line.text)) {
        final dateStr = _findDateInText(line.text);
        if (dateStr != null) return dateStr;
      }
    }

    // Scan all lines for any date
    for (final line in lines) {
      final dateStr = _findDateInText(line.text);
      if (dateStr != null) return dateStr;
    }

    return null;
  }

  /// Extract registration number (FPA, EPA, etc.).
  static String? _extractRegistrationNo(List<_AnnotatedLine> lines) {
    for (final line in lines) {
      final match = _registrationPattern.firstMatch(line.text);
      if (match != null) {
        return match.group(1) ?? match.group(0);
      }
    }

    // Look for "Reg. No." style labels
    final regLabel = RegExp(
      r'reg(?:istration)?\s*(?:no|number|#)?\s*\.?\s*[:.]?\s*(\S+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = regLabel.firstMatch(line.text);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Find and normalize a date string within text.
  static String? _findDateInText(String text) {
    final m1 = _datePatterns[0].firstMatch(text);
    if (m1 != null) {
      final day = m1.group(1)!.padLeft(2, '0');
      final month = m1.group(2)!.padLeft(2, '0');
      final year = m1.group(3)!;
      return '$year-$month-$day';
    }

    final m2 = _datePatterns[1].firstMatch(text);
    if (m2 != null) {
      final year = m2.group(1)!;
      final month = m2.group(2)!.padLeft(2, '0');
      final day = m2.group(3)!.padLeft(2, '0');
      return '$year-$month-$day';
    }

    final m3 = _datePatterns[2].firstMatch(text);
    if (m3 != null) {
      final monthName = m3.group(1)!;
      final day = m3.group(2)!.padLeft(2, '0');
      final year = m3.group(3)!;
      final month = _monthNumber(monthName);
      return '$year-$month-$day';
    }

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
}

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
