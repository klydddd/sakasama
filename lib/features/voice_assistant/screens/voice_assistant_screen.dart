import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/features/voice_assistant/widgets/conversation_bubble.dart';
import 'package:sakasama/features/voice_assistant/widgets/microphone_button.dart';
import 'package:sakasama/features/voice_assistant/widgets/suggested_questions.dart';

/// Voice assistant screen — "Tanungin si Saka".
///
/// Features a centered microphone button, status indicator,
/// scrollable conversation bubbles, and suggested question chips.
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool _isListening = false;

  // Mock conversation data
  final List<_Message> _messages = [
    _Message(text: 'Ano ang PhilGAP?', isUser: true),
    _Message(
      text:
          'Ang PhilGAP o Philippine Good Agricultural Practices ay isang programa ng gobyerno na nagsisiguro na ang mga produktong agricultural ay ligtas at may mataas na kalidad. Kapag naging certified ka, maaari kang magbenta sa mga malalaking tindahan at mag-export.',
      isUser: false,
    ),
  ];

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
  }

  void _onQuestionTap(String question) {
    setState(() {
      _messages.add(_Message(text: question, isUser: true));
      // Simulated response
      _messages.add(
        _Message(
          text:
              'Salamat sa iyong tanong tungkol sa "$question". '
              'Bilang isang magsasaka, mahalaga na sundin ang mga hakbang ng PhilGAP certification.',
          isUser: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.backgroundGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌾', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Text(AppStrings.voiceAssistantTitle),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Conversation Area ──────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    reverse: false,
                    padding: const EdgeInsets.all(AppDimensions.screenPadding),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ConversationBubble(
                            text: msg.text,
                            isUser: msg.isUser,
                          )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
          ),

          // ── Status Indicator ──────────────────────────────────────
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(duration: 600.ms)
                      .then()
                      .fadeOut(duration: 600.ms),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.listening,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ── Suggested Questions ────────────────────────────────────
          SuggestedQuestions(onQuestionTap: _onQuestionTap),

          const SizedBox(height: AppDimensions.itemSpacing),

          // ── Microphone Button ──────────────────────────────────────
          Center(
            child: MicrophoneButton(
              isListening: _isListening,
              onPressed: _toggleListening,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: 8),

          Text(
            AppStrings.tapToSpeak,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
          ),

          const SizedBox(height: AppDimensions.screenPadding),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.backgroundGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌾', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: AppDimensions.itemSpacing),
          Text(
            'Kamusta! Ako si Saka.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tanungin mo ako tungkol sa PhilGAP.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _Message {
  const _Message({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
