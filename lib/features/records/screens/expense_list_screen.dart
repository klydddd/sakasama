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

/// Provider that watches all expense records.
final _expenseListProvider = StreamProvider<List<ExpenseRecord>>((ref) {
  final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
  return ref.watch(expenseDaoProvider).watchAll(userId);
});

/// Screen listing all expense records.
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(_expenseListProvider);
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
                'Expenses Record',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE3F2FD), AppColors.scaffoldBackground],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmpty(
                    context,
                    '📋',
                    'Walang expense records pa',
                    'Mag-scan ng resibo para magsimula.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                sliver: SliverList.builder(
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) {
                    final e = expenses[i];
                    return _ExpenseTile(
                      expense: e,
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

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.dateFmt});
  final ExpenseRecord expense;
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
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.info,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(expense.expenseDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (expense.totalValue != null)
            Text(
              '₱${expense.totalValue!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.info,
              ),
            ),
        ],
      ),
    );
  }
}
