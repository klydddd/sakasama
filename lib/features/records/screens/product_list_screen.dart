import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/database_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that watches all product records.
final _productListProvider = StreamProvider<List<ProductRecord>>((ref) {
  final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
  return ref.watch(productDaoProvider).watchAll(userId);
});

/// Screen listing all product records.
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_productListProvider);

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
                'Product Records',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF8E1), AppColors.scaffoldBackground],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmpty(
                    context,
                    '📦',
                    'Walang product records pa',
                    'Mag-scan ng produkto para magsimula.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                sliver: SliverList.builder(
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return _ProductTile(
                      product: p,
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

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final ProductRecord product;

  Color get _categoryColor => switch (product.category) {
    'fertilizer' => const Color(0xFF6A1B9A),
    'pesticide' => const Color(0xFFE65100),
    'herbicide' => const Color(0xFF2E7D32),
    'fungicide' => const Color(0xFF00695C),
    'seed' => const Color(0xFF1565C0),
    _ => AppColors.textGrey,
  };

  IconData get _categoryIcon => switch (product.category) {
    'fertilizer' => Icons.science_rounded,
    'pesticide' => Icons.bug_report_rounded,
    'herbicide' => Icons.grass_rounded,
    'fungicide' => Icons.spa_rounded,
    'seed' => Icons.eco_rounded,
    _ => Icons.inventory_2_rounded,
  };

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
              color: _categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon, color: _categoryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (product.manufacturer != null) ...[
                      Text(
                        product.manufacturer!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (product.netWeight != null)
                      Text(
                        product.netWeight!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (product.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.category!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _categoryColor,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
