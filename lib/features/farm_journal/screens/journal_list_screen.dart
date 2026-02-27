import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/features/farm_journal/widgets/activity_log_tile.dart';

/// Journal list screen showing all logged farm activities.
///
/// Displays entries grouped by date in a scrollable list.
/// Shows an empty state when no entries exist.
/// FAB to add new entries.
class JournalListScreen extends StatelessWidget {
  const JournalListScreen({super.key});

  // Mock data for UI demonstration
  static final List<_MockEntry> _mockEntries = [
    _MockEntry(
      type: AppStrings.fertilization,
      product: 'Urea 46-0-0',
      date: 'Feb 26, 2026',
      icon: Icons.science_rounded,
      color: const Color(0xFF6A1B9A),
    ),
    _MockEntry(
      type: AppStrings.irrigation,
      product: 'Sprinkler system',
      date: 'Feb 25, 2026',
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF1565C0),
    ),
    _MockEntry(
      type: AppStrings.pestControl,
      product: 'Neem oil spray',
      date: 'Feb 24, 2026',
      icon: Icons.bug_report_rounded,
      color: const Color(0xFFE65100),
    ),
    _MockEntry(
      type: AppStrings.planting,
      product: 'Hybrid rice seeds',
      date: 'Feb 23, 2026',
      icon: Icons.grass_rounded,
      color: AppColors.primaryGreen,
    ),
    _MockEntry(
      type: AppStrings.soilPrep,
      product: 'Organic compost',
      date: 'Feb 22, 2026',
      icon: Icons.landscape_rounded,
      color: const Color(0xFF795548),
    ),
    _MockEntry(
      type: AppStrings.harvest,
      product: 'Palay - 5 sacks',
      date: 'Feb 20, 2026',
      icon: Icons.agriculture_rounded,
      color: const Color(0xFFF57F17),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.farmJournal),
        centerTitle: false,
      ),
      body: _mockEntries.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              itemCount: _mockEntries.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.itemSpacing,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_mockEntries.length} na entry',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms);
                }

                final entry = _mockEntries[index - 1];
                return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.smallSpacing + 2,
                      ),
                      child: ActivityLogTile(
                        activityType: entry.type,
                        productUsed: entry.product,
                        date: entry.date,
                        icon: entry.icon,
                        iconColor: entry.color,
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
}

class _MockEntry {
  const _MockEntry({
    required this.type,
    required this.product,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String type;
  final String product;
  final String date;
  final IconData icon;
  final Color color;
}
