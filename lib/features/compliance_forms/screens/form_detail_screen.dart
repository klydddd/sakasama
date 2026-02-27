import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Detail view of a pre-filled compliance form with editable fields.
class FormDetailScreen extends StatelessWidget {
  const FormDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.formFarmJournal),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.statusIncomplete,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Farm Info Header ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.backgroundGreen,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bukid ni Juan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Laguna, Los Baños  •  Palay (Rice)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saklaw: Feb 1, 2026 - May 1, 2026',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Form Fields ───────────────────────────────────────────
            _buildFormSection(context, 'Impormasyon ng Magsasaka', [
              _FormField('Pangalan', 'Juan Dela Cruz'),
              _FormField('Farm ID', 'SK-2026-001'),
              _FormField('Lokasyon', 'Laguna, Los Baños'),
            ]),

            const SizedBox(height: AppDimensions.itemSpacing),

            _buildFormSection(context, 'Aktibidad sa Bukid', [
              _FormField('Kabuuang Entry', '12'),
              _FormField('Huling Entry', 'Feb 26, 2026'),
              _FormField('Nawawalang Araw', '5'),
            ]),

            const SizedBox(height: AppDimensions.itemSpacing),

            _buildFormSection(context, 'Mga Input na Ginamit', [
              _FormField('Pataba', 'Urea 46-0-0, Complete 14-14-14'),
              _FormField('Pestisidyo', 'Neem oil spray'),
              _FormField('Binhi', 'Hybrid rice seeds'),
            ]),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Save Button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppDimensions.primaryButtonHeight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Na-save ang form!')),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: Text(AppStrings.save),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(
    BuildContext context,
    String title,
    List<_FormField> fields,
  ) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          const Divider(),
          ...fields.map(
            (field) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      field.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      field.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _FormField {
  const _FormField(this.label, this.value);
  final String label;
  final String value;
}
