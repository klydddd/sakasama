import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sakasama/data/models/ocr_result.dart';

/// OCR service using Hugging Face Inference API with Qwen2.5-VL-7B-Instruct.
///
/// Sends a base64-encoded image to the Hugging Face model endpoint
/// and parses the structured JSON response into an [OcrResult].
///
/// Requires an internet connection and a valid `HUGGINGFACE_API_KEY` in `.env`.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  bool _isProcessing = false;

  /// Whether an inference is currently in progress.
  bool get isProcessing => _isProcessing;

  /// The Hugging Face Inference API endpoint (OpenAI-compatible).
  static const String _modelEndpoint =
      'https://router.huggingface.co/v1/chat/completions';

  /// System prompt that instructs the model to extract receipt fields as JSON.
  static const String _systemPrompt =
      '''You are an expert receipt/document OCR assistant. Analyze the provided image and extract the following fields from it. Return ONLY a valid JSON object with these keys:
- "product": product name(s) found (comma-separated if multiple)
- "price": price with currency (e.g. "150.00 PHP")
- "quantity": quantity with unit (e.g. "3 pcs")
- "supplier": store/supplier name
- "date": date in YYYY-MM-DD format
- "raw_text": all text visible in the image

If a field cannot be found, set its value to null. Do not include any text outside the JSON object.''';

  /// Run the OCR pipeline on an image file via Hugging Face API.
  ///
  /// 1. Reads the image and base64-encodes it.
  /// 2. Sends it to Qwen2.5-VL-7B-Instruct via the HF Inference API.
  /// 3. Parses the structured JSON response into [OcrResult].
  Future<OcrResult> processImage(String imagePath) async {
    if (_isProcessing) {
      throw StateError('May kasalukuyang OCR na ginagawa.');
    }

    _isProcessing = true;

    try {
      final apiKey = dotenv.env['HUGGINGFACE_API_KEY'];
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'your_huggingface_api_key_here') {
        throw StateError(
          'HUGGINGFACE_API_KEY is not set. Please add your API key to the .env file.',
        );
      }

      // Read and base64-encode the image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw StateError('Image file not found: $imagePath');
      }
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Determine MIME type from extension
      final ext = imagePath.toLowerCase().split('.').last;
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      // Build the request body for the chat completions endpoint
      final requestBody = jsonEncode({
        'model': 'Qwen/Qwen2.5-VL-7B-Instruct',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
              },
              {
                'type': 'text',
                'text':
                    'Extract all receipt/label information from this image and return it as JSON.',
              },
            ],
          },
        ],
        'max_tokens': 1024,
        'temperature': 0.1,
      });

      // Send request to Hugging Face
      final response = await http.post(
        Uri.parse(_modelEndpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        throw StateError(
          'Hugging Face API error (${response.statusCode}): ${response.body}',
        );
      }

      // Parse the response
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = responseJson['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        return OcrResult.fromRawText(
          '(Walang response mula sa AI model)',
          imagePath: imagePath,
        );
      }

      final messageContent = choices[0]['message']['content'] as String? ?? '';

      if (messageContent.trim().isEmpty) {
        return OcrResult.fromRawText(
          '(Walang text na nakita sa image)',
          imagePath: imagePath,
        );
      }

      // Try to parse the model output as JSON
      return _parseModelResponse(messageContent, imagePath);
    } finally {
      _isProcessing = false;
    }
  }

  /// Parse the model's text response, extracting JSON if present.
  OcrResult _parseModelResponse(String content, String imagePath) {
    try {
      // The model might wrap JSON in markdown code fences
      String jsonStr = content.trim();

      // Remove markdown code fences if present
      if (jsonStr.startsWith('```')) {
        final lines = jsonStr.split('\n');
        // Remove first line (```json) and last line (```)
        lines.removeAt(0);
        if (lines.isNotEmpty && lines.last.trim() == '```') {
          lines.removeLast();
        }
        jsonStr = lines.join('\n').trim();
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Build confidence map — all fields from the API are considered confident
      final confidence = <String, bool>{
        'date': parsed['date'] != null,
        'supplier': parsed['supplier'] != null,
        'product': parsed['product'] != null,
        'price': parsed['price'] != null,
        'quantity': parsed['quantity'] != null,
      };

      return OcrResult(
        product: parsed['product'] as String?,
        price: parsed['price'] as String?,
        quantity: parsed['quantity'] as String?,
        supplier: parsed['supplier'] as String?,
        date: parsed['date'] as String?,
        rawText: parsed['raw_text'] as String?,
        imagePath: imagePath,
        confidence: confidence,
      );
    } catch (_) {
      // If JSON parsing fails, return the raw text
      return OcrResult.fromRawText(content, imagePath: imagePath);
    }
  }
}
