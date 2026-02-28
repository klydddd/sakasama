import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/database_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that watches all harvest records.
final _harvestListProvider = StreamProvider<List<HarvestRecord>>((ref) {
  final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
  return ref.watch(harvestDaoProvider).watchAll(userId);
});

/// Screen listing all harvest records.
class HarvestListScreen extends ConsumerWidget {
  const HarvestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harvestsAsync = ref.watch(_harvestListProvider);
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.scaffoldBackground,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Harvesting Record',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F5E9), AppColors.scaffoldBackground],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          harvestsAsync.when(
            data: (harvests) {
              if (harvests.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmpty(
                    context,
                    '🌾',
                    'Walang harvest records pa',
                    'Mag-scan ng ani para magsimula.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                sliver: SliverList.builder(
                  itemCount: harvests.length,
                  itemBuilder: (ctx, i) {
                    final h = harvests[i];
                    return _HarvestTile(
                      harvest: h,
                      dateFmt: dateFmt,
                    ).animate().fadeIn(delay: (100 * i).ms, duration: 300.ms);
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _HarvestTile extends StatelessWidget {
  const _HarvestTile({required this.harvest, required this.dateFmt});
  final HarvestRecord harvest;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.backgroundGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grass_rounded,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  harvest.cropName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(harvest.harvestDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (harvest.totalVolumeKg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${harvest.totalVolumeKg!.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
