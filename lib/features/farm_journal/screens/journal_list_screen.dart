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

/// Filter mode for the journal list.
enum JournalFilter { all, date, type }

/// Journal list screen showing all logged farm activities from the local DB.
///
/// Uses a CustomScrollView with a SliverAppBar (gradient background) that
/// collapses on scroll. Includes filter chips for All / Date / Type.
class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  JournalFilter _activeFilter = JournalFilter.all;
  String? _selectedType;
  bool _sortNewestFirst = true;

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

  /// Format date: omit year if same year as now.
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Apply the active filter to the list.
  List<ActivityLog> _applyFilter(List<ActivityLog> activities) {
    var result = List<ActivityLog>.from(activities);

    switch (_activeFilter) {
      case JournalFilter.all:
        break;
      case JournalFilter.date:
        // Sort by date
        result.sort(
          (a, b) => _sortNewestFirst
              ? b.activityDate.compareTo(a.activityDate)
              : a.activityDate.compareTo(b.activityDate),
        );
        return result;
      case JournalFilter.type:
        if (_selectedType != null) {
          result = result
              .where((a) => a.activityType == _selectedType)
              .toList();
        }
        break;
    }

    return result;
  }

  /// Get unique activity types from entries.
  List<String> _getUniqueTypes(List<ActivityLog> activities) {
    return activities.map((a) => a.activityType).toSet().toList()..sort();
  }

  void _showTypePicker(BuildContext context, List<String> types) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Piliin ang uri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(),
                // "All types" option
                ListTile(
                  leading: const Icon(Icons.select_all_rounded),
                  title: const Text('Lahat ng uri'),
                  selected: _selectedType == null,
                  onTap: () {
                    setState(() => _selectedType = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...types.map((type) {
                  final info = _iconForType(type);
                  return ListTile(
                    leading: Icon(info.icon, color: info.color),
                    title: Text(type),
                    selected: _selectedType == type,
                    onTap: () {
                      setState(() => _selectedType = type);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(allActivitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('May error: $error')),
        data: (activities) {
          if (activities.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverFillRemaining(child: _buildEmptyState(context)),
              ],
            );
          }
          return _buildScrollableList(context, activities);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            FloatingActionButton(
                  onPressed: () => context.push('/journal/add'),
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  child: const Icon(Icons.add_rounded, size: 28),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 1, end: 0, curve: Curves.easeOutBack),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      collapsedHeight: kToolbarHeight,
      iconTheme: const IconThemeData(color: AppColors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkGreen, AppColors.primaryGreen],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
          title: Text(
            AppStrings.farmJournal,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
        ),
      ),
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

  Widget _buildScrollableList(
    BuildContext context,
    List<ActivityLog> activities,
  ) {
    final filtered = _applyFilter(activities);
    final types = _getUniqueTypes(activities);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(context),

        // ── Filter chips ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.itemSpacing,
              AppDimensions.screenPadding,
              10,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Lahat',
                    icon: Icons.list_rounded,
                    selected: _activeFilter == JournalFilter.all,
                    onTap: () => setState(() {
                      _activeFilter = JournalFilter.all;
                      _selectedType = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _sortNewestFirst ? 'Pinakabago' : 'Pinakaluma',
                    icon: Icons.calendar_today_rounded,
                    selected: _activeFilter == JournalFilter.date,
                    onTap: () => setState(() {
                      if (_activeFilter == JournalFilter.date) {
                        _sortNewestFirst = !_sortNewestFirst;
                      } else {
                        _activeFilter = JournalFilter.date;
                        _sortNewestFirst = true;
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _selectedType ?? 'Uri ng aktibidad',
                    icon: Icons.filter_list_rounded,
                    selected: _activeFilter == JournalFilter.type,
                    onTap: () {
                      setState(() => _activeFilter = JournalFilter.type);
                      _showTypePicker(context, types);
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),

        // ── Result count ──────────────────────────────────────────
        // SliverToBoxAdapter(
        //   child: Padding(
        //     padding: const EdgeInsets.fromLTRB(
        //       AppDimensions.screenPadding,
        //       8,
        //       AppDimensions.screenPadding,
        //       AppDimensions.itemSpacing,
        //     ),
        //     child: Text(
        //       '${filtered.length} na entry',
        //       style: Theme.of(
        //         context,
        //       ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
        //     ),
        //   ),
        // ),

        // ── Activity entries ──────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = filtered[index];
              final typeInfo = _iconForType(entry.activityType);

              return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.smallSpacing + 2,
                    ),
                    child: ActivityLogTile(
                      activityType: entry.activityType,
                      productUsed: entry.productUsed ?? '',
                      date: _formatDate(entry.activityDate),
                      icon: typeInfo.icon,
                      iconColor: typeInfo.color,
                      onTap: () {
                        // Will navigate to detail screen in future
                      },
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 80 * index),
                    duration: 400.ms,
                  )
                  .slideX(begin: 0.05, end: 0);
            }, childCount: filtered.length),
          ),
        ),

        // Bottom padding for FAB clearance
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

/// Styled filter chip.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.primaryGreen
                : AppColors.textLight.withValues(alpha: 0.3),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.white : AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.white : AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
