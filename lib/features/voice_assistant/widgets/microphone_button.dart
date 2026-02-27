import 'package:flutter/material.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';

/// Animated microphone button for the voice assistant.
///
/// 80dp circular green button with mic icon. Pulses when listening.
class MicrophoneButton extends StatefulWidget {
  const MicrophoneButton({
    super.key,
    required this.onPressed,
    this.isListening = false,
  });

  final VoidCallback onPressed;
  final bool isListening;

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isListening ? _pulseAnimation.value : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer glow ring when listening ───────────────────────
          if (widget.isListening)
            Container(
              width: AppDimensions.micButtonSize + 24,
              height: AppDimensions.micButtonSize + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
              ),
            ),

          // ── Main button ─────────────────────────────────────────
          GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: AppDimensions.micButtonSize,
              height: AppDimensions.micButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isListening
                      ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                      : [AppColors.darkGreen, AppColors.primaryGreen],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.isListening
                                ? AppColors.error
                                : AppColors.primaryGreen)
                            .withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: AppColors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
