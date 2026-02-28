import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/core/services/farm_data_context.dart';
import 'package:sakasama/core/services/gemini_chat_service.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Singleton provider for [GeminiChatService].
final geminiChatServiceProvider = Provider<GeminiChatService>((ref) {
  return GeminiChatService();
});

/// Provider for [FarmDataContext] — builds RAG context from DB.
final farmDataContextProvider = Provider<FarmDataContext>((ref) {
  return FarmDataContext(
    farmDao: ref.watch(farmDaoProvider),
    activityDao: ref.watch(activityDaoProvider),
    expenseDao: ref.watch(expenseDaoProvider),
    harvestDao: ref.watch(harvestDaoProvider),
    productDao: ref.watch(productDaoProvider),
  );
});

/// Chat message model.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.timestamp,
  });

  final String text;
  final bool isUser;
  final bool isLoading;
  final DateTime? timestamp;
}

/// Notifier managing the chat message list and interactions with Gemini.
///
/// Before each message, queries [FarmDataContext] to inject the user's
/// farm data into the prompt (RAG).
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this._chatService, this._farmDataContext) : super([]);

  final GeminiChatService _chatService;
  final FarmDataContext _farmDataContext;

  bool get isProcessing => state.isNotEmpty && state.last.isLoading;

  /// Send a user message and get an AI response.
  ///
  /// Automatically injects the user's farm data context
  /// so the AI can answer questions about their records.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isProcessing) return;

    // Add user message
    state = [
      ...state,
      ChatMessage(text: text.trim(), isUser: true, timestamp: DateTime.now()),
    ];

    // Add loading placeholder
    state = [
      ...state,
      const ChatMessage(text: '', isUser: false, isLoading: true),
    ];

    // Build farm data context for RAG
    String? farmContext;
    try {
      farmContext = await _farmDataContext.buildContext();
    } catch (_) {
      // Proceed without context if it fails
    }

    // Get AI response with farm context
    final response = await _chatService.sendMessage(
      text.trim(),
      farmContext: farmContext,
    );

    // Replace loading placeholder with actual response
    state = [
      ...state.sublist(0, state.length - 1),
      ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
    ];
  }

  /// Clear all messages and reset the chat session.
  void clearChat() {
    _chatService.resetChat();
    state = [];
  }
}

/// Provider for the chat notifier.
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
      final chatService = ref.watch(geminiChatServiceProvider);
      final farmDataContext = ref.watch(farmDataContextProvider);
      return ChatNotifier(chatService, farmDataContext);
    });
