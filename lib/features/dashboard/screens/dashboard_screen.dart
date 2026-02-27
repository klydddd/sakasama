import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/farm_providers.dart';
import 'package:sakasama/features/dashboard/widgets/action_button_card.dart';
import 'package:sakasama/features/dashboard/widgets/progress_card.dart';

/// Main dashboard / home screen.
///
/// Shows a time-aware greeting with the farmer's real name from the DB,
/// progress card with days logged, and 4 large action buttons.
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

    // Extract farmer name from profile, fallback to 'Magsasaka'
    final farmerName = farmProfileAsync.when(
      data: (farm) => farm?.farmerName ?? 'Magsasaka',
      loading: () => 'Magsasaka',
      error: (_, __) => 'Magsasaka',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting with real name ──────────────────────────────
            Text(
              '${_getGreeting()}, $farmerName! 👋',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05, end: 0),

            const SizedBox(height: AppDimensions.smallSpacing),

            Text(
              'Ano ang gagawin natin ngayong araw?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textGrey),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Progress Card ─────────────────────────────────────────
            const ProgressCard(daysLogged: 12, totalDays: 90),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Section Title ─────────────────────────────────────────
            Text(
              'Mga Aksyon',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.itemSpacing),

            // ── Action Buttons Grid ───────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppDimensions.itemSpacing,
              mainAxisSpacing: AppDimensions.itemSpacing,
              childAspectRatio: 1.1,
              children: [
                ActionButtonCard(
                      icon: Icons.camera_alt_rounded,
                      label: AppStrings.scanReceipt,
                      iconColor: const Color(0xFF1565C0),
                      onTap: () => context.push('/scan'),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
                ActionButtonCard(
                      icon: Icons.edit_note_rounded,
                      label: AppStrings.logActivity,
                      iconColor: AppColors.primaryGreen,
                      onTap: () => context.push('/journal/add'),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
                ActionButtonCard(
                      icon: Icons.mic_rounded,
                      label: AppStrings.askSaka,
                      iconColor: const Color(0xFF6A1B9A),
                      onTap: () => context.go('/voice'),
                    )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
                ActionButtonCard(
                      icon: Icons.file_download_rounded,
                      label: AppStrings.exportReport,
                      iconColor: const Color(0xFFE65100),
                      onTap: () => context.go('/export'),
                    )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
              ],
            ),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Quick Stats ───────────────────────────────────────────
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
              child: Row(
                children: [
                  _buildStatItem(context, '12', 'Entry', Icons.edit_rounded),
                  _buildDivider(),
                  _buildStatItem(
                    context,
                    '3',
                    'Scan',
                    Icons.camera_alt_rounded,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    context,
                    '78%',
                    'Kumpleto',
                    Icons.check_circle_rounded,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 48, color: AppColors.divider);
  }
}
