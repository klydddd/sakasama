import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Full-screen welcome screen shown on first app launch.
///
/// Features a green gradient background, large Sakasama wordmark,
/// tagline in Filipino, and an animated "Magsimula" button.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkGreen,
              AppColors.primaryGreen,
              Color(0xFF43A047),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo Icon ─────────────────────────────────────────
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        size: 64,
                        color: AppColors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: AppDimensions.sectionSpacing),

                // ── App Name ──────────────────────────────────────────
                Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: AppDimensions.itemSpacing),

                // ── Tagline ───────────────────────────────────────────
                Text(
                      AppStrings.appTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: AppDimensions.smallSpacing),

                // ── Subtitle ──────────────────────────────────────────
                Text(
                  'Saka + Kasama',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                const Spacer(flex: 3),

                // ── Get Started Button ────────────────────────────────
                SizedBox(
                      width: double.infinity,
                      height: AppDimensions.primaryButtonHeight,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.go('/onboarding/model-download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryGreen,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.buttonRadius,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.getStarted,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontSize: AppDimensions.buttonTextSize,
                                  ),
                            ),
                            const SizedBox(width: AppDimensions.smallSpacing),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms)
                    .slideY(begin: 0.5, end: 0),

                const SizedBox(height: AppDimensions.sectionSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
