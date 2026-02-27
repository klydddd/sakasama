import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Export screen for generating PDF/CSV compliance reports.
///
/// Shows summary card with entry count, date range, completion %,
/// PDF/CSV toggle, and generate & share button.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedFormat = 'PDF';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.exportTitle),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary Card ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.cardPadding * 1.25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkGreen, AppColors.primaryGreen],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Buod ng Ulat',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.itemSpacing),
                  Row(
                    children: [
                      _buildSummaryItem(
                        context,
                        '12',
                        AppStrings.totalEntries,
                        Icons.edit_rounded,
                      ),
                      _buildVerticalDivider(),
                      _buildSummaryItem(
                        context,
                        '78%',
                        AppStrings.completionRate,
                        Icons.pie_chart_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.itemSpacing),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.chipRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          color: AppColors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Feb 1, 2026 - Feb 27, 2026',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Format Selection ──────────────────────────────────────
            Text(
              'Format ng Ulat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.itemSpacing),

            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    context,
                    AppStrings.formatPdf,
                    Icons.picture_as_pdf_rounded,
                    'Opisyal na PhilGAP format',
                  ),
                ),
                const SizedBox(width: AppDimensions.itemSpacing),
                Expanded(
                  child: _buildFormatOption(
                    context,
                    AppStrings.formatCsv,
                    Icons.table_chart_rounded,
                    'Para sa spreadsheet',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Included Forms ────────────────────────────────────────
            Text(
              'Kasama sa Ulat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.itemSpacing),

            _buildIncludedItem(
              context,
              AppStrings.formFarmJournal,
              true,
              '12 entry',
            ),
            _buildIncludedItem(
              context,
              AppStrings.formPestMonitoring,
              true,
              '3 entry',
            ),
            _buildIncludedItem(
              context,
              AppStrings.formHarvestRecord,
              false,
              '2 entry',
            ),
            _buildIncludedItem(
              context,
              AppStrings.formInputInventory,
              true,
              '8 entry',
            ),

            const SizedBox(height: AppDimensions.sectionSpacing),

            // ── Generate Button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppDimensions.primaryButtonHeight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ginagawa ang ulat... (mock)'),
                    ),
                  );
                },
                icon: const Icon(Icons.file_download_rounded),
                label: Text(AppStrings.generateAndShare),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

            const SizedBox(height: AppDimensions.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.8), size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildFormatOption(
    BuildContext context,
    String format,
    IconData icon,
    String description,
  ) {
    final isSelected = _selectedFormat == format;

    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundGreen : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
            ),
            const SizedBox(height: 8),
            Text(
              format,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludedItem(
    BuildContext context,
    String title,
    bool isEnabled,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              isEnabled
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isEnabled ? AppColors.primaryGreen : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
