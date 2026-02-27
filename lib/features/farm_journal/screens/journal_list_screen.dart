import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/activity_providers.dart';
import 'package:sakasama/features/farm_journal/widgets/activity_log_tile.dart';

/// Journal list screen showing all logged farm activities from the local DB.
///
/// Displays entries in a scrollable list, reactively updated via Riverpod.
/// Shows an empty state when no entries exist.
/// FAB to add new entries.
class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  /// Map an activity type string to an icon and color.
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.farmJournal),
        centerTitle: false,
      ),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('May error: $error')),
        data: (activities) {
          if (activities.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildList(context, activities);
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
                onPressed: () => context.push('/journal/add'),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  AppStrings.addEntry,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 1, end: 0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.backgroundGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: AppColors.lightGreen,
            ),
          ),
          const SizedBox(height: AppDimensions.itemSpacing),
          Text(
            AppStrings.emptyJournalTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          Text(
            AppStrings.emptyJournalMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ActivityLog> activities) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      itemCount: activities.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.itemSpacing),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  '${activities.length} na entry',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms);
        }

        final entry = activities[index - 1];
        final typeInfo = _iconForType(entry.activityType);

        return Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.smallSpacing + 2,
              ),
              child: ActivityLogTile(
                activityType: entry.activityType,
                productUsed: entry.productUsed ?? '',
                date: dateFormat.format(entry.activityDate),
                icon: typeInfo.icon,
                iconColor: typeInfo.color,
                onTap: () {
                  // Will navigate to detail screen in future
                },
              ),
            )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 400.ms,
            )
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}
