import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Compliance overview card showing the 5 PhilGAP form types with status.
///
/// Styled to match the RecentActivityCard (large icons, spacious rows).
class ComplianceOverviewCard extends ConsumerWidget {
  const ComplianceOverviewCard({super.key});

  static const List<({String label, IconData icon, Color color, String? route})>
  _forms = [
    (
      label: AppStrings.formFarmJournal,
      icon: Icons.menu_book_rounded,
      color: Color(0xFF2E7D32),
      route: '/journal',
    ),
    (
      label: AppStrings.formPestMonitoring,
      icon: Icons.bug_report_rounded,
      color: Color(0xFFE65100),
      route: null,
    ),
    (
      label: AppStrings.formHarvestRecord,
      icon: Icons.agriculture_rounded,
      color: Color(0xFFF57F17),
      route: '/records/harvests',
    ),
    (
      label: AppStrings.formInputInventory,
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF1565C0),
      route: '/records/products',
    ),
    (
      label: AppStrings.formWaterSource,
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0277BD),
      route: '/records/expenses',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceDao = ref.watch(complianceDaoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Compliance Checklist',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              GestureDetector(
                onTap: () => context.push('/compliance'),
                child: Text(
                  'Tingnan Lahat',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form items
              FutureBuilder<Map<String, bool>>(
                future: _loadCompletionStatus(complianceDao),
                builder: (context, snapshot) {
                  final statusMap = snapshot.data ?? {};

                  return Column(
                    children: [
                      for (int i = 0; i < _forms.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _FormRow(
                          label: _forms[i].label,
                          icon: _forms[i].icon,
                          color: _forms[i].color,
                          isComplete: statusMap[_forms[i].label] ?? false,
                          onTap: _forms[i].route != null
                              ? () => context.push(_forms[i].route!)
                              : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, bool>> _loadCompletionStatus(dynamic complianceDao) async {
    try {
      final records = await complianceDao.getAll();
      final Map<String, bool> result = {};
      for (final record in records) {
        if (record.status == 'complete') {
          result[record.formType] = true;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.isComplete,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isComplete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: isComplete ? color : AppColors.textLight,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppColors.textDark : AppColors.textMedium,
                ),
              ),
            ),
            Icon(
              isComplete ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 22,
              color: isComplete ? AppColors.primaryGreen : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
