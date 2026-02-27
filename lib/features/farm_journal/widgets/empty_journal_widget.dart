import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Empty state widget shown when the farm journal has no entries.
///
/// Displays an encouraging illustration placeholder, friendly message,
/// and a prominent action button to start logging.
class EmptyJournalWidget extends StatelessWidget {
  const EmptyJournalWidget({super.key, this.onStartLogging});

  final VoidCallback? onStartLogging;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sectionSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Illustration ──────────────────────────────────────────
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: AppColors.lightGreen,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Title ─────────────────────────────────────────────────
            Text(
              AppStrings.emptyJournalTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.smallSpacing),

            // ── Message ───────────────────────────────────────────────
            Text(
              AppStrings.emptyJournalMessage,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textGrey),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Action Button ─────────────────────────────────────────
            SizedBox(
              width: 260,
              height: AppDimensions.secondaryButtonHeight,
              child: ElevatedButton.icon(
                onPressed: onStartLogging,
                icon: const Icon(Icons.add_rounded),
                label: Text(AppStrings.startLogging),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
