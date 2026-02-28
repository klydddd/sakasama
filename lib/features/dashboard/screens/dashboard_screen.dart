import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/activity_providers.dart';
import 'package:sakasama/data/providers/farm_providers.dart';
import 'package:sakasama/data/providers/database_providers.dart';
import 'package:sakasama/features/dashboard/widgets/compliance_overview_card.dart';
import 'package:sakasama/features/dashboard/widgets/growth_tracker_card.dart';

/// Main dashboard / home screen.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger sync with Supabase when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).syncAll();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 18) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final farmProfileAsync = ref.watch(activeFarmProfileProvider);
    final daysLoggedAsync = ref.watch(daysLoggedProvider);

    final farmerName = farmProfileAsync.when(
      data: (farm) => farm?.farmerName ?? 'Magsasaka',
      loading: () => 'Magsasaka',
      error: (_, __) => 'Magsasaka',
    );

    final daysLogged = daysLoggedAsync.when(
      data: (days) => days,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textGrey),
            onPressed: () => context.push('/settings'),
            tooltip: AppStrings.settings,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable content with pinned tracker ──────────────
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Greeting ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.screenPadding,
                      AppDimensions.screenPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              '${_getGreeting()},',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideX(begin: -0.05, end: 0),
                        const SizedBox(height: 4),
                        Text(
                              '$farmerName!',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 500.ms)
                            .slideX(begin: -0.05, end: 0),
                        const SizedBox(height: AppDimensions.sectionSpacing),
                      ],
                    ),
                  ),
                ),

                // ── Pinned Growth Tracker ────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: GrowthTrackerHeaderDelegate(
                    daysLogged: daysLogged,
                    totalDays: 90,
                  ),
                ),

                // ── Cards below ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      8, // Decreased top gap
                      AppDimensions.screenPadding,
                      AppDimensions.screenPadding,
                    ),
                    child: Column(
                      children: [
                        // ── Records Section ─────────────────────────
                        _RecordsSection().animate().fadeIn(
                          delay: 300.ms,
                          duration: 400.ms,
                        ),

                        const SizedBox(height: 36),

                        // Compliance Checklist
                        const ComplianceOverviewCard().animate().fadeIn(
                          delay: 400.ms,
                          duration: 400.ms,
                        ),

                        const SizedBox(height: AppDimensions.sectionSpacing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Sleek Accessible Bottom Navigation ──────────────────────────
      extendBody:
          true, // Allows the body to scroll behind the transparent nav bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child:
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  AppColors.white.withValues(alpha: 0.85),
                  BlendMode.srcOver,
                ),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left Action 1: Scan
                      _NavAction(
                        icon: Icons.camera_alt_rounded,
                        label: 'Scan',
                        onTap: () => context.push('/scan'),
                      ),

                      // Left Action 2: Export
                      _NavAction(
                        icon: Icons.file_download_rounded,
                        label: 'Export',
                        onTap: () => context.push('/export'),
                      ),

                      // Center Action: Voice Conversation (Mic)
                      _CenterAction(
                        icon: Icons.mic_rounded,
                        label: 'Saka',
                        onTap: () => context.push('/conversation'),
                      ),

                      // Right Action 1: Add Log
                      _NavAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Log',
                        onTap: () => context.push('/journal/add'),
                      ),

                      // Right Action 2: Text Chat
                      _NavAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        onTap: () => context.push('/voice'),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(
              begin: 1.0,
              end: 0,
              delay: 500.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

/// Standard secondary actions for the new navigation bar
class _NavAction extends StatefulWidget {
  const _NavAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavAction> createState() => _NavActionState();
}

class _NavActionState extends State<_NavAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _scaleCtrl.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (context, child) => Transform.scale(
          scale: 1.0 - (_scaleCtrl.value * 0.1),
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: AppColors.textMedium, size: 26),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800, // High contrast, bold
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prominent central action button (FAB equivalent) embedded in the nav
class _CenterAction extends StatefulWidget {
  const _CenterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_CenterAction> createState() => _CenterActionState();
}

class _CenterActionState extends State<_CenterAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _scaleCtrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (context, child) => Transform.scale(
          scale: 1.0 - (_scaleCtrl.value * 0.05),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(
                  bottom: 6,
                  top: 4,
                ), // Push it up slightly
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: AppColors.white, size: 28),
              ),
              // We integrate the label directly into the bar, highly visible
              // Text(
              //   widget.label,
              //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //         color: AppColors.textDark,
              //         fontWeight: FontWeight.w800,
              //         fontSize: 12,
              //       ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal record navigation section for the dashboard.
class _RecordsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RecordNavCard(
                icon: Icons.menu_book_rounded,
                label: 'Activities',
                color: AppColors.primaryGreen,
                onTap: () => context.push('/journal'),
              ),
            ),
            const SizedBox(width: AppDimensions.itemSpacing),
            Expanded(
              child: _RecordNavCard(
                icon: Icons.receipt_long_rounded,
                label: 'Expenses',
                color: AppColors.primaryGreen,
                onTap: () => context.push('/records/expenses'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.itemSpacing),
        Row(
          children: [
            Expanded(
              child: _RecordNavCard(
                icon: Icons.grass_rounded,
                label: 'Harvests',
                color: AppColors.primaryGreen,
                onTap: () => context.push('/records/harvests'),
              ),
            ),
            const SizedBox(width: AppDimensions.itemSpacing),
            Expanded(
              child: _RecordNavCard(
                icon: Icons.inventory_2_rounded,
                label: 'Products',
                color: AppColors.primaryGreen,
                onTap: () => context.push('/records/products'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single record navigation card.
class _RecordNavCard extends StatelessWidget {
  const _RecordNavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 236, 236, 236),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 18,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(icon, color: color, size: 72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
