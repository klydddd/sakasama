import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/database_providers.dart';
import 'package:sakasama/data/providers/farm_providers.dart';

/// Settings screen with language, profile, about, and data backup options.
///
/// Reads the farmer's name and farm info from the local database.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmProfileAsync = ref.watch(activeFarmProfileProvider);

    // Extract profile info with fallbacks
    final farmerName = farmProfileAsync.when(
      data: (farm) => farm?.farmerName ?? 'Magsasaka',
      loading: () => '...',
      error: (_, __) => 'Magsasaka',
    );
    final farmInfo = farmProfileAsync.when(
      data: (farm) {
        if (farm == null) return 'Walang farm profile';
        final parts = <String>[];
        if (farm.farmName.isNotEmpty) parts.add(farm.farmName);
        if (farm.location != null && farm.location!.isNotEmpty) {
          parts.add(farm.location!);
        }
        return parts.isNotEmpty ? parts.join(' • ') : 'Walang detalye';
      },
      loading: () => '...',
      error: (_, __) => 'Walang farm profile',
    );

    // Get user email from Supabase auth
    final userEmail = ref.watch(supabaseClientProvider).auth.currentUser?.email;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          // ── Profile Card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding * 1.25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkGreen, AppColors.primaryGreen],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppDimensions.itemSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        farmInfo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      if (userEmail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  color: AppColors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: AppDimensions.sectionSpacing),

          // ── Settings Items ──────────────────────────────────────────
          Text(
            'Pangkalahatang Setting',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: AppDimensions.smallSpacing),

          _buildSettingsTile(
            context,
            icon: Icons.language_rounded,
            title: AppStrings.language,
            subtitle: 'Filipino',
            iconColor: const Color(0xFF1565C0),
            onTap: () {},
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

          _buildSettingsTile(
            context,
            icon: Icons.landscape_rounded,
            title: AppStrings.editFarmProfile,
            subtitle: 'Pangalan, lokasyon, pananim',
            iconColor: AppColors.primaryGreen,
            onTap: () {},
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

          _buildSettingsTile(
            context,
            icon: Icons.description_rounded,
            title: AppStrings.complianceForms,
            subtitle: 'Tingnan ang mga PhilGAP form',
            iconColor: const Color(0xFFE65100),
            onTap: () => context.push('/compliance'),
          ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

          const SizedBox(height: AppDimensions.itemSpacing),

          Text(
            'Data at Privacy',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 300.ms),

          const SizedBox(height: AppDimensions.smallSpacing),

          _buildSettingsTile(
            context,
            icon: Icons.backup_rounded,
            title: AppStrings.dataBackup,
            subtitle: 'I-backup ang datos sa lokal na file',
            iconColor: const Color(0xFF6A1B9A),
            onTap: () {},
          ).animate().fadeIn(delay: 700.ms, duration: 300.ms),

          _buildSettingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: AppStrings.aboutAndHelp,
            subtitle: 'Gabay sa PhilGAP at tungkol sa app',
            iconColor: const Color(0xFF00838F),
            onTap: () {},
          ).animate().fadeIn(delay: 800.ms, duration: 300.ms),

          const SizedBox(height: AppDimensions.itemSpacing),

          // ── Logout Button ──────────────────────────────────────────
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: AppStrings.logout,
            subtitle: 'Mag-logout sa iyong account',
            iconColor: AppColors.error,
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ).animate().fadeIn(delay: 900.ms, duration: 300.ms),

          const SizedBox(height: AppDimensions.sectionSpacing),

          // ── Version ─────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.appName} v1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
                ),
                Text(
                  'Saka + Kasama',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

          const SizedBox(height: AppDimensions.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
