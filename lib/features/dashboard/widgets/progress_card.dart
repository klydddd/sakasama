import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';

/// Animated circular progress card showing days logged out of 90.
///
/// Features a green progress ring, day count, and descriptive label.
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, this.daysLogged = 12, this.totalDays = 90});

  final int daysLogged;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final progress = daysLogged / totalDays;
    final daysRemaining = totalDays - daysLogged;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.cardPadding * 1.25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Progress Ring ──────────────────────────────────────────
          SizedBox(
            width: AppDimensions.progressRingSize,
            height: AppDimensions.progressRingSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: AppDimensions.progressRingSize,
                  height: AppDimensions.progressRingSize,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: AppDimensions.progressRingStroke,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppDimensions.progressRingSize,
                  height: AppDimensions.progressRingSize,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: AppDimensions.progressRingStroke,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  '$daysLogged',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimensions.cardPadding * 1.25),

          // ── Info ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Araw na Naka-log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'sa $totalDays Araw',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                // ── Progress Bar ────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: AppColors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  '$daysRemaining araw pa bago mag-audit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}
