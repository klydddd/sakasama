import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sakasama/data/models/ocr_result.dart';

/// OCR service using Google Gemini 2.5 Flash with vision capabilities.
///
/// Sends an image to Gemini, which classifies the scanned item
/// (receipt, product, or crop) and extracts structured data.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  bool _isProcessing = false;
  GenerativeModel? _model;

  /// Whether an inference is currently in progress.
  bool get isProcessing => _isProcessing;

  GenerativeModel _getModel() {
    if (_model != null) return _model!;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('YOUR_')) {
      throw StateError(
        'GEMINI_API_KEY is not set. Add your API key to the .env file.',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 2048,
      ),
    );
    return _model!;
  }

  /// Run the OCR pipeline on an image file via Gemini Vision.
  Future<OcrResult> processImage(String imagePath) async {
    if (_isProcessing) {
      throw StateError('May kasalukuyang OCR na ginagawa.');
    }

    _isProcessing = true;

    try {
      final model = _getModel();

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw StateError('Image file not found: $imagePath');
      }
      final imageBytes = await imageFile.readAsBytes();

      // Determine MIME type
      final ext = imagePath.toLowerCase().split('.').last;
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      final response = await model.generateContent([
        Content.multi([
          DataPart(mimeType, imageBytes),
          TextPart(
            'Analyze this image. Classify it and extract all relevant information as JSON. '
            'Return ONLY a valid JSON object, no markdown fences.',
          ),
        ]),
      ]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return OcrResult.fromRawText(
          '(Walang nakita sa image)',
          imagePath: imagePath,
        );
      }

      return _parseResponse(text, imagePath);
    } finally {
      _isProcessing = false;
    }
  }

  /// Parse Gemini's text response into OcrResult.
  OcrResult _parseResponse(String content, String imagePath) {
    try {
      String jsonStr = content.trim();

      // Remove markdown code fences if present
      if (jsonStr.startsWith('```')) {
        final lines = jsonStr.split('\n');
        lines.removeAt(0);
        if (lines.isNotEmpty && lines.last.trim() == '```') {
          lines.removeLast();
        }
        jsonStr = lines.join('\n').trim();
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      return OcrResult.fromJson(parsed, imagePath: imagePath);
    } catch (_) {
      return OcrResult.fromRawText(content, imagePath: imagePath);
    }
  }

  static const String _systemPrompt = '''
You are an expert agricultural image analyzer for Filipino farmers. When given an image, classify it into one of these categories and extract relevant information.

## Classification Rules

1. **receipt** — If the image is a receipt, invoice, or expense record (e.g., purchase of fertilizer, seeds, pesticides, supplies). Look for prices, store names, itemized lists, dates.

2. **product** — If the image shows a product like a bag of fertilizer, pesticide bottle, seed packet, or any agricultural input product. Look for product labels, brand names, ingredients, net weight, manufacturing info.

3. **crop** — If the image shows harvested crops, vegetables, fruits, or produce ready for sale/record. Look for the type of crop visible.

## Response Format

Return ONLY a valid JSON object. Always include `"scan_type"` as the first field.

### For receipt:
```json
{
  "scan_type": "receipt",
  "date": "YYYY-MM-DD or null",
  "supplier": "store/supplier name or null",
  "items": [
    {
      "description": "item name/description",
      "quantity": "amount or null",
      "unit": "pcs/kg/L/etc or null",
      "price_per_unit": "numeric value or null",
      "total_value": "line item total or null"
    }
  ],
  "total_value": "receipt grand total or null",
  "raw_text": "all visible text"
}
```
**IMPORTANT for receipts**: If the receipt lists multiple items, include ALL items in the "items" array. Each item should have its own description, quantity, unit, price_per_unit, and total_value. If there is only one item, still use the "items" array with one entry.

### For product:
```json
{
  "scan_type": "product",
  "product_name": "product name",
  "product_description": "what the product is for",
  "manufacturer": "manufacturer/brand or null",
  "net_weight": "weight with unit or null",
  "expiration_date": "YYYY-MM-DD or null",
  "category": "fertilizer|pesticide|seed|herbicide|fungicide|other",
  "raw_text": "all visible text"
}
```

### For crop:
```json
{
  "scan_type": "crop",
  "crop_name": "name of the crop/produce",
  "total_volume_kg": "estimated weight in kg or null",
  "raw_text": "any visible text or description"
}
```

## Important
- If you cannot determine the scan type, use "receipt" as default
- Set fields to null if the information is not visible
- For Filipino text, translate product names to Filipino if appropriate
- Prices should be numeric values only (no currency symbols)
- Dates should be in YYYY-MM-DD format
''';
}
