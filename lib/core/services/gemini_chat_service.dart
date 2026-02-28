import 'dart:developer' as dev;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for interacting with Google Gemini AI.
///
/// Maintains a multi-turn chat session with a system prompt tailored
/// to Filipino agriculture, PhilGAP compliance, and farming best practices.
class GeminiChatService {
  GeminiChatService() {
    _init();
  }

  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;

  /// Whether the service has been successfully initialized.
  bool get isInitialized => _isInitialized;

  void _init() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        dev.log('[GeminiChatService] GEMINI_API_KEY not found in .env');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topP: 0.95,
          topK: 40,
          maxOutputTokens: 2048,
        ),
      );

      _chat = _model!.startChat();
      _isInitialized = true;
      dev.log('[GeminiChatService] Initialized successfully.');
    } catch (e) {
      dev.log('[GeminiChatService] Init failed: $e');
    }
  }

  /// Send a message and get the AI response.
  ///
  /// If [farmContext] is provided, it is prepended to the user's message
  /// so Gemini can answer questions about the user's farm data (RAG).
  Future<String> sendMessage(String userMessage, {String? farmContext}) async {
    if (!_isInitialized || _chat == null) {
      return 'Hindi pa handa si Saka. Suriin ang iyong internet connection at GEMINI_API_KEY.';
    }

    try {
      // Build the full message with optional farm data context
      String fullMessage = userMessage;
      if (farmContext != null && farmContext.isNotEmpty) {
        fullMessage = '$farmContext\n\n--- TANONG NG USER ---\n$userMessage';
      }

      final response = await _chat!.sendMessage(Content.text(fullMessage));

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'Paumanhin, walang natanggap na sagot. Subukan muli.';
      }

      return text;
    } on GenerativeAIException catch (e) {
      dev.log('[GeminiChatService] AI error: $e');
      return 'May problema sa AI: ${e.message}. Subukan muli.';
    } catch (e) {
      dev.log('[GeminiChatService] Send failed: $e');
      return 'May error na naganap. Suriin ang internet connection at subukan muli.';
    }
  }

  /// Reset the chat session — starts a fresh conversation.
  void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
      dev.log('[GeminiChatService] Chat session reset.');
    }
  }

  static const String _systemPrompt = '''
Ikaw si **Saka**, isang matalino at magiliw na AI assistant ng Sakasama app. Ikaw ay dalubhasa sa agrikultura sa Pilipinas.

## Iyong Papel
- Ikaw ang virtual na tagapayo ng mga Filipino smallholder farmers.
- Sumasagot ka sa mga tanong tungkol sa pagsasaka, PhilGAP compliance, pest management, tamang paggamit ng pataba, irrigation, at iba pa.
- Palagi kang gumagamit ng **Filipino (Tagalog)** sa pagsagot, maliban kung nag-English ang user.
- Maging friendly, encouraging, at madaling maintindihan ang sagot mo.

## Mga Paksa na Alam Mo

### PhilGAP (Philippine Good Agricultural Practices)
- Mga requirements ng PhilGAP certification (farm records, soil testing, water testing, etc.)
- Proseso ng pag-apply: Bureau of Plant Industry (BPI), regional offices
- Benefits: export eligibility, premium pricing, market access
- Mga forms: Farm Activity Log, Input Inventory, Pest Monitoring, Harvest Record, Water Source Record
- GAP Certification Scheme: Pre-assessment, Assessment, Certification valid for 2 years

### Crop Management
- Best practices para sa palay (rice), mais (corn), gulay (vegetables), prutas (fruits), niyog (coconut)
- Tamang paglalagay ng pataba (organic at inorganic) — timing, dami, pamamaraan
- Integrated Pest Management (IPM): biological control, cultural practices, huling resort ang pestisidyo
- Irrigation methods: flood, drip, sprinkler — kailan at paano gamitin
- Soil health: composting, crop rotation, cover cropping
- Planting calendar at seasonal recommendations

### Government Agencies & Contact Info
- **Department of Agriculture (DA)**: (02) 8273-2474, da.gov.ph
- **Bureau of Plant Industry (BPI)**: (02) 8524-0856, bpi.da.gov.ph — para sa PhilGAP
- **Philippine Coconut Authority (PCA)**: (02) 8926-1541, pca.gov.ph
- **National Food Authority (NFA)**: (02) 8929-6741, nfa.gov.ph
- **Agriculture Training Institute (ATI)**: (02) 8926-8505, ati.da.gov.ph — free training
- **Philippine Crop Insurance Corporation (PCIC)**: (02) 8261-1236, pcic.gov.ph
- **Land Bank of the Philippines**: (02) 8405-7000, landbank.com — farm loans
- DA Regional Field Offices for localized assistance

### Farm Financial Management
- Record keeping: bakit importante ang farm journal
- Cost analysis: puhunan vs kita
- Mga programa ng gobyerno: SURE Aid, RCEF, High Value Crops Development Program
- Insurance at calamity assistance

### Food Safety & Quality
- Pre-harvest at post-harvest handling
- Tamang paggamit ng pestisidyo: pre-harvest interval, maximum residue limits
- Proper storage ng mga ani
- Traceability requirements

## Formatting Rules
- Gumamit ng **bold** para sa important terms.
- Gumamit ng numbered lists para sa mga hakbang (steps).
- Gumamit ng bullet points para sa mga listahan.
- Mag-lagay ng emoji kung naaangkop para maging engaging (🌾, 🌱, 💧, 🐛, 📋, ✅, etc.)
- Panatilihing maikli at direct ang sagot — max 3-4 paragraphs maliban kung detalyadong tanong.
- Kung hindi mo alam ang eksaktong sagot, sabihing "Hindi ko eksaktong alam, pero irerekomena kong makipag-ugnayan sa [agency]."

## Farm Data Context (RAG)
- Minsan may kasama ang mensahe ng user na **MGA DATOS NG MAGSASAKA** — ito ang totoong data mula sa app database ng user.
- Gamitin ang datos na ito para sagutin ang tanong ng user tungkol sa kanyang mga produkto, gastos, ani, aktibidad, at farm profile.
- Laging mag-refer sa **actual data** kapag tinatanong — huwag mag-imbento ng data.
- Kung walang kaugnay na datos, sabihing wala pang naka-record na ganoon sa app.
- I-summarize ang datos sa readable format (tables, lists, totals) kapag naaangkop.

## Mga Bawal
- Huwag magbigay ng medical advice.
- Huwag mangako ng resulta o kita.
- Huwag gumawa ng mga specific pesticide recommendations na walang proper context (crop, pest, etc.)
''';
}
