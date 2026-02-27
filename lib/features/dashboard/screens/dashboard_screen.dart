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
import 'package:sakasama/features/dashboard/widgets/compliance_overview_card.dart';
import 'package:sakasama/features/dashboard/widgets/growth_tracker_card.dart';
import 'package:sakasama/features/dashboard/widgets/recent_activity_card.dart';

/// Main dashboard / home screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 18) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                    padding: const EdgeInsets.all(AppDimensions.screenPadding),
                    child: Column(
                      children: [
                        // Recent Activity
                        const RecentActivityCard().animate().fadeIn(
                          delay: 300.ms,
                          duration: 400.ms,
                        ),

                        const SizedBox(height: AppDimensions.itemSpacing),

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

          // ── Bottom action buttons ───────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient fade: white → transparent
              Container(
                height: 16,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.white, Color(0x00FFFFFF)],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                color: AppColors.white,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CircleActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: AppStrings.scanReceipt,
                        onTap: () => context.push('/scan'),
                        delay: 400,
                      ),
                      _CircleActionButton(
                        icon: Icons.add_rounded,
                        label: AppStrings.logActivity,
                        onTap: () => context.push('/journal/add'),
                        delay: 500,
                      ),
                      _CircleActionButton(
                        icon: Icons.chat_rounded,
                        label: AppStrings.askSaka,
                        onTap: () => context.push('/voice'),
                        delay: 600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A circular action button with green gradient fill and white icon.
class _CircleActionButton extends StatefulWidget {
  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.delay = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int delay;

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
          listenable: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnim.value, child: child);
          },
          child: GestureDetector(
            onTapDown: (_) {
              _scaleCtrl.forward();
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) => _scaleCtrl.reverse(),
            onTapCancel: () => _scaleCtrl.reverse(),
            onTap: widget.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.darkGreen, AppColors.primaryGreen],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 28, color: AppColors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.delay),
          duration: 400.ms,
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          delay: Duration(milliseconds: widget.delay),
          duration: 400.ms,
        );
  }
}
