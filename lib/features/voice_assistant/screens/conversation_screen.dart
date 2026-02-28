import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/services/voice_service.dart';
import 'package:sakasama/data/providers/chat_providers.dart';
import 'package:go_router/go_router.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  String _currentSpeech = '';
  String _aiResponse = '';
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(voiceServiceProvider).initSpeech();
      _playGreeting();
    });
  }

  Future<void> _playGreeting() async {
    final aiText = "Kumusta! Ako si Saka. Pindutin ang mic para magsalita.";
    setState(() {
      _aiResponse = aiText;
    });
    await ref.read(voiceServiceProvider).speak(aiText);
  }

  @override
  void dispose() {
    ref.read(voiceServiceProvider).stopListening();
    ref.read(voiceServiceProvider).stopSpeaking();
    super.dispose();
  }

  void _toggleListening() async {
    final voiceService = ref.read(voiceServiceProvider);

    if (_isListening) {
      await voiceService.stopListening();
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      _processUserSpeech(_currentSpeech);
    } else {
      await voiceService.stopSpeaking();
      setState(() {
        _isListening = true;
        _currentSpeech = '';
        _aiResponse = '';
      });
      await voiceService.startListening((recognizedWords) {
        setState(() {
          _currentSpeech = recognizedWords;
        });
      });
    }
  }

  Future<void> _processUserSpeech(String speech) async {
    if (speech.trim().isEmpty) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final chatService = ref.read(geminiChatServiceProvider);
    final farmDataContext = ref.read(farmDataContextProvider);

    String? contextData;
    try {
      contextData = await farmDataContext.buildContext();
    } catch (_) {}

    final response = await chatService.sendMessage(
      speech,
      farmContext: contextData,
    );

    setState(() {
      _aiResponse = response;
      _isProcessing = false;
    });

    await ref.read(voiceServiceProvider).speak(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Kausapin si Saka",
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _aiResponse.isEmpty
                            ? "Nakikinig si Saka..."
                            : _aiResponse,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textDark, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_currentSpeech.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    '"$_currentSpeech"',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                ),
              GestureDetector(
                onTap: _toggleListening,
                child:
                    Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.redAccent
                                : AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isListening
                                            ? Colors.redAccent
                                            : AppColors.primaryGreen)
                                        .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: _isListening ? 10 : 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: AppColors.white,
                            size: 48,
                          ),
                        )
                        .animate(target: _isListening ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
