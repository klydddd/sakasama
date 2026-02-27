import 'package:flutter/material.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/features/dashboard/widgets/wheat_growth_painter.dart';

/// Growth tracker card that collapses from full (wheat + text) to thin bar.
///
/// Used inside a SliverPersistentHeader — receives [shrinkOffset] and
/// [maxExtent] / [minExtent] to interpolate between expanded and collapsed.
class GrowthTrackerCard extends StatelessWidget {
  const GrowthTrackerCard({
    super.key,
    required this.daysLogged,
    this.totalDays = 90,
    this.collapseFraction = 0.0,
  });

  final int daysLogged;
  final int totalDays;

  /// 0.0 = fully expanded, 1.0 = fully collapsed.
  final double collapseFraction;

  String _stageLabel(double progress) {
    if (progress <= 0.05) return 'Binhi';
    if (progress <= 0.20) return 'Sumibol';
    if (progress <= 0.50) return 'Lumalaki';
    if (progress <= 0.80) return 'Nagkakauhay';
    return 'Hinog na';
  }

  String _stageDescription(double progress) {
    if (progress <= 0.05) return 'Magsimula na mag-log!';
    if (progress <= 0.20) return 'Maganda ang simula!';
    if (progress <= 0.50) return 'Patuloy na lumalaki';
    if (progress <= 0.80) return 'Malapit na!';
    return 'Napakahusay!';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (daysLogged / totalDays).clamp(0.0, 1.0);
    final daysRemaining = (totalDays - daysLogged).clamp(0, totalDays);
    final t = collapseFraction.clamp(0.0, 1.0);

    // Interpolated values
    final wheatWidth = 60.0 * (1.0 - t);
    final wheatGap = 12.0 * (1.0 - t);
    final vertPadding = 14.0 * (1.0 - t * 0.4);
    final horizPadding = 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizPadding,
        vertical: vertPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.cardRadius * (1.0 - t * 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3 * (1.0 - t)),
            blurRadius: 16 * (1.0 - t),
            offset: Offset(0, 6 * (1.0 - t)),
          ),
        ],
      ),
      child: ClipRect(
        child: Row(
          children: [
            // ── Wheat Growth Canvas (shrinks to 0 width) ──────────────
            if (t < 0.95)
              SizedBox(
                width: wheatWidth,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CustomPaint(
                      size: Size(wheatWidth, double.infinity),
                      painter: WheatGrowthPainter(progress: value),
                    );
                  },
                ),
              ),

            if (t < 0.95) SizedBox(width: wheatGap),

            // ── Text Info ─────────────────────────────────────────────
            Expanded(
              child: t > 0.7
                  // ── Collapsed: single-row compact view ──────────────
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _stageLabel(progress),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$daysLogged / $totalDays araw',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: AppColors.white.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  // ── Expanded: full multi-line view ──────────────────
                  : SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stage label badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _stageLabel(progress),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Days logged
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$daysLogged',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                TextSpan(
                                  text: ' / $totalDays araw',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Progress bar
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
                                  backgroundColor: AppColors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Description
                          Text(
                            _stageDescription(progress),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$daysRemaining araw pa bago mag-audit',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate for the collapsible growth tracker.
class GrowthTrackerHeaderDelegate extends SliverPersistentHeaderDelegate {
  GrowthTrackerHeaderDelegate({required this.daysLogged, this.totalDays = 90});

  final int daysLogged;
  final int totalDays;

  @override
  double get maxExtent => 160;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant GrowthTrackerHeaderDelegate oldDelegate) {
    return oldDelegate.daysLogged != daysLogged ||
        oldDelegate.totalDays != totalDays;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final fraction = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding * (1.0 - fraction * 0.4),
        vertical: 4,
      ),
      child: GrowthTrackerCard(
        daysLogged: daysLogged,
        totalDays: totalDays,
        collapseFraction: fraction,
      ),
    );
  }
}
