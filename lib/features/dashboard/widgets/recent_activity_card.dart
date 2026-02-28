import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/activity_providers.dart';

/// A compact card showing the last 3 journal entries.
///
/// Links to the full journal list. Shows empty state when no entries exist.
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  static ({IconData icon, Color color}) _iconForType(String type) {
    if (type == AppStrings.fertilization) {
      return (icon: Icons.science_rounded, color: const Color(0xFF6A1B9A));
    }
    if (type == AppStrings.irrigation) {
      return (icon: Icons.water_drop_rounded, color: const Color(0xFF1565C0));
    }
    if (type == AppStrings.pestControl) {
      return (icon: Icons.bug_report_rounded, color: const Color(0xFFE65100));
    }
    if (type == AppStrings.planting) {
      return (icon: Icons.grass_rounded, color: AppColors.primaryGreen);
    }
    if (type == AppStrings.soilPrep) {
      return (icon: Icons.landscape_rounded, color: const Color(0xFF795548));
    }
    if (type == AppStrings.harvest) {
      return (icon: Icons.agriculture_rounded, color: const Color(0xFFF57F17));
    }
    if (type == AppStrings.pruning) {
      return (icon: Icons.content_cut_rounded, color: const Color(0xFF00897B));
    }
    return (icon: Icons.note_alt_rounded, color: AppColors.textGrey);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(allActivitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mga Aktibidad',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              GestureDetector(
                onTap: () => context.push('/journal'),
                child: Text(
                  'Tingnan Lahat',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              activitiesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (activities) {
                  if (activities.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 32,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Wala pang entry — magsimula na!',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final recent = activities.take(3).toList();
                  return Column(
                    children: [
                      for (int i = 0; i < recent.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ActivityRow(activity: recent[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityLog activity;

  @override
  Widget build(BuildContext context) {
    final typeInfo = RecentActivityCard._iconForType(activity.activityType);
    final dateFormat = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(typeInfo.icon, color: typeInfo.color, size: 36),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityType,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (activity.productUsed != null &&
                    activity.productUsed!.isNotEmpty)
                  Text(
                    activity.productUsed!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            dateFormat.format(activity.activityDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
