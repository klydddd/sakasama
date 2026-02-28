import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/chat_providers.dart';

/// "Tanungin si Saka" AI chat screen.
///
/// Full chat UI with:
/// - Scrollable message list with markdown-rendered AI responses
/// - Text input field with send button
/// - Suggested question chips when conversation is empty
/// - Typing indicator while AI is processing
class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final message = text ?? _controller.text;
    if (message.trim().isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();

    await ref.read(chatNotifierProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  void _onSuggestedTap(String question) {
    _sendMessage(question);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatNotifierProvider);

    // Auto-scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌾', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.voiceAssistantTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Text(
                //   'AI-powered farming assistant',
                //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //     color: AppColors.textGrey,
                //     fontSize: 11,
                //   ),
                // ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Bagong usapan',
              onPressed: () {
                ref.read(chatNotifierProvider.notifier).clearChat();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages Area ──────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.smallSpacing,
                      AppDimensions.screenPadding,
                      AppDimensions.screenPadding,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _ChatBubble(
                        message: msg,
                        isLast: index == messages.length - 1,
                      );
                    },
                  ),
          ),

          // ── Input Area ────────────────────────────────────────────
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Avatar
          Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌾', style: TextStyle(fontSize: 44)),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 20),

          Text(
            'Sakasama',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 8),

          Text(
            'Ang iyong kasama sa pagsasaka!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // Suggested Questions
          Text(
            'Mga mungkahing tanong:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 12),

          ..._suggestedQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SuggestionCard(
                    icon: q['icon'] as IconData,
                    text: q['text'] as String,
                    onTap: () => _onSuggestedTap(q['text'] as String),
                  ),
                )
                .animate()
                .fadeIn(delay: (500 + index * 100).ms, duration: 400.ms)
                .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final isProcessing = ref.watch(chatNotifierProvider.notifier).isProcessing;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        10,
        AppDimensions.screenPadding,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isProcessing,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Magtanong kay Saka...',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isProcessing
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isProcessing ? AppColors.textLight : null,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isProcessing ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: AppColors.white,
                size: 22,
              ),
              onPressed: isProcessing ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  static final List<Map<String, dynamic>> _suggestedQuestions = [
    {
      'icon': Icons.verified_rounded,
      'text': 'Ano ang PhilGAP at paano mag-apply?',
    },
    {
      'icon': Icons.bug_report_rounded,
      'text': 'Paano ko makokontrolan ang mga peste sa gulay?',
    },
    {
      'icon': Icons.grass_rounded,
      'text': 'Ano ang tamang pataba para sa palay?',
    },
    {
      'icon': Icons.contact_phone_rounded,
      'text': 'Saan ako pwedeng humingi ng tulong sa DA?',
    },
    {
      'icon': Icons.water_drop_rounded,
      'text': 'Anong best irrigation method para sa maliit na bukid?',
    },
  ];
}

// ── Chat Bubble Widget ──────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, this.isLast = false});

  final ChatMessage message;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return _buildLoadingBubble(context);
    }

    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? AppColors.primaryGreen : AppColors.cardShadow)
                  .withValues(alpha: isUser ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                  strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                  h1: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  h3: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  blockquoteDecoration: BoxDecoration(
                    border: const Border(
                      left: BorderSide(color: AppColors.primaryGreen, width: 3),
                    ),
                    color: AppColors.backgroundGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tableBorder: TableBorder.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                  tableHead: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLoadingBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
            const SizedBox(width: 10),
            Text(
              'Nag-iisip si Saka...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDot(int index) {
    return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(delay: (index * 200).ms, duration: 400.ms)
        .then()
        .fadeOut(duration: 400.ms);
  }
}

// ── Suggestion Card ─────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.backgroundGreen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
