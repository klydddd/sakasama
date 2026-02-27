import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// List of PhilGAP ICS compliance form types with status badges.
class FormsListScreen extends StatelessWidget {
  const FormsListScreen({super.key});

  static final List<_FormType> _formTypes = [
    _FormType(
      title: AppStrings.formFarmJournal,
      icon: Icons.menu_book_rounded,
      isComplete: true,
      entries: 12,
    ),
    _FormType(
      title: AppStrings.formPestMonitoring,
      icon: Icons.bug_report_rounded,
      isComplete: false,
      entries: 3,
    ),
    _FormType(
      title: AppStrings.formHarvestRecord,
      icon: Icons.agriculture_rounded,
      isComplete: false,
      entries: 2,
    ),
    _FormType(
      title: AppStrings.formInputInventory,
      icon: Icons.inventory_2_rounded,
      isComplete: true,
      entries: 8,
    ),
    _FormType(
      title: AppStrings.formWaterSource,
      icon: Icons.water_drop_rounded,
      isComplete: false,
      entries: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        itemCount: _formTypes.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.itemSpacing),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

          final form = _formTypes[index - 1];
          return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDimensions.smallSpacing + 2,
                ),
                child: _buildFormTile(context, form),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: 400.ms,
              )
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildFormTile(BuildContext context, _FormType form) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/compliance/detail'),
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
                  color: form.isComplete
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  form.icon,
                  color: form.isComplete
                      ? AppColors.success
                      : AppColors.warning,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimensions.smallSpacing + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${form.entries} na entry',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: form.isComplete
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
                ),
                child: Text(
                  form.isComplete
                      ? '✅ ${AppStrings.statusComplete}'
                      : '⚠️ ${AppStrings.statusIncomplete}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: form.isComplete
                        ? AppColors.success
                        : AppColors.warning,
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

class _FormType {
  const _FormType({
    required this.title,
    required this.icon,
    required this.isComplete,
    required this.entries,
  });

  final String title;
  final IconData icon;
  final bool isComplete;
  final int entries;
}
