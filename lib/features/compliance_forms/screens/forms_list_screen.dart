import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// List of PhilGAP ICS compliance form types with live status from the database.
class FormsListScreen extends ConsumerWidget {
  const FormsListScreen({super.key});

  static const List<_FormDef> _formDefs = [
    _FormDef(
      title: AppStrings.formFarmJournal,
      icon: Icons.menu_book_rounded,
      formType: AppStrings.formFarmJournal,
      route: '/journal',
    ),
    _FormDef(
      title: AppStrings.formPestMonitoring,
      icon: Icons.bug_report_rounded,
      formType: AppStrings.formPestMonitoring,
      route: null,
    ),
    _FormDef(
      title: AppStrings.formHarvestRecord,
      icon: Icons.agriculture_rounded,
      formType: AppStrings.formHarvestRecord,
      route: '/records/harvests',
    ),
    _FormDef(
      title: AppStrings.formInputInventory,
      icon: Icons.inventory_2_rounded,
      formType: AppStrings.formInputInventory,
      route: '/records/products',
    ),
    _FormDef(
      title: AppStrings.formWaterSource,
      icon: Icons.water_drop_rounded,
      formType: AppStrings.formWaterSource,
      route: '/records/expenses',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceDao = ref.watch(complianceDaoProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.complianceForms),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Map<String, bool>>(
        future: _loadStatus(complianceDao),
        builder: (context, snapshot) {
          final statusMap = snapshot.data ?? {};

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            itemCount: _formDefs.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.itemSpacing,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGreen,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.inputRadius,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Kumpletuhin ang lahat ng form para sa PhilGAP certification.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms);
              }

              final form = _formDefs[index - 1];
              final isComplete = statusMap[form.formType] ?? false;

              return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.smallSpacing + 2,
                    ),
                    child: _buildFormTile(context, form, isComplete),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    duration: 400.ms,
                  )
                  .slideX(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  Future<Map<String, bool>> _loadStatus(dynamic complianceDao) async {
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

  Widget _buildFormTile(BuildContext context, _FormDef form, bool isComplete) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: form.route != null ? () => context.push(form.route!) : null,
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  form.icon,
                  color: isComplete ? AppColors.success : AppColors.warning,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimensions.smallSpacing + 4),
              Expanded(
                child: Text(
                  form.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
                ),
                child: Text(
                  isComplete
                      ? AppStrings.statusComplete
                      : AppStrings.statusIncomplete,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormDef {
  const _FormDef({
    required this.title,
    required this.icon,
    required this.formType,
    this.route,
  });

  final String title;
  final IconData icon;
  final String formType;
  final String? route;
}
