import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/models/ocr_result.dart';
import 'package:sakasama/data/providers/ocr_providers.dart';
import 'package:sakasama/features/ocr_scan/widgets/extracted_field_card.dart';

/// OCR review screen showing extracted fields from a scanned receipt.
///
/// Receives an image path, runs GLM-OCR inference, displays structured
/// results in editable cards, and lets the user confirm & save.
class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  OcrResult? _editableResult;

  @override
  void initState() {
    super.initState();
    // Start OCR processing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ocrInferenceProvider.notifier).processImage(widget.imagePath);
    });
  }

  @override
  void dispose() {
    ref.read(ocrInferenceProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrInferenceProvider);

    // When OCR completes, initialize editable result
    if (ocrState.status == OcrStatus.done &&
        ocrState.result != null &&
        _editableResult == null) {
      _editableResult = ocrState.result;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(AppStrings.reviewTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              children: [
                // ── Image Preview ───────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: AppDimensions.sectionSpacing),

                // ── Processing States ───────────────────────────────────
                if (ocrState.status == OcrStatus.initializing)
                  _buildStatusCard(
                    icon: Icons.memory_rounded,
                    message: 'Sinusuri ang OCR engine...',
                    isLoading: true,
                  ),

                if (ocrState.status == OcrStatus.processing)
                  _buildStatusCard(
                    icon: Icons.document_scanner_rounded,
                    message:
                        '${AppStrings.processing}${ocrState.activeStrategy != null ? ' (${ocrState.activeStrategy})' : ''}',
                    isLoading: true,
                  ),

                if (ocrState.status == OcrStatus.error)
                  _buildErrorCard(ocrState.error ?? 'Unknown error'),

                // ── Success Banner ──────────────────────────────────────
                if (ocrState.status == OcrStatus.done &&
                    _editableResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.inputRadius,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Matagumpay na na-scan! Suriin ang mga detalye sa ibaba.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: AppDimensions.sectionSpacing),

                  // ── Extracted Fields ─────────────────────────────────
                  ..._buildFieldCards(),
                ],
              ],
            ),
          ),

          // ── Bottom Buttons ──────────────────────────────────────────
          if (ocrState.status == OcrStatus.done && _editableResult != null)
            Container(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppDimensions.secondaryButtonHeight,
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(AppStrings.retake),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.itemSpacing),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: AppDimensions.secondaryButtonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: save to activity repository
                            context.go('/journal');
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text(AppStrings.confirmAndSave),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Retry button on error
          if (ocrState.status == OcrStatus.error)
            Container(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppDimensions.secondaryButtonHeight,
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(AppStrings.retake),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.itemSpacing),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: AppDimensions.secondaryButtonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () => ref
                              .read(ocrInferenceProvider.notifier)
                              .processImage(widget.imagePath),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(AppStrings.retry),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldCards() {
    final result = _editableResult!;
    final fields = <_FieldEntry>[
      if (result.product != null)
        _FieldEntry(
          AppStrings.productName,
          result.product!,
          result.isFieldConfident('product'),
        ),
      if (result.activeIngredient != null)
        _FieldEntry(
          AppStrings.activeIngredient,
          result.activeIngredient!,
          result.isFieldConfident('activeIngredient'),
        ),
      if (result.dosage != null)
        _FieldEntry(
          AppStrings.dosage,
          result.dosage!,
          result.isFieldConfident('dosage'),
        ),
      if (result.manufacturer != null)
        _FieldEntry(
          AppStrings.manufacturer,
          result.manufacturer!,
          result.isFieldConfident('manufacturer'),
        ),
      if (result.netWeight != null)
        _FieldEntry(
          AppStrings.netWeight,
          result.netWeight!,
          result.isFieldConfident('netWeight'),
        ),
      if (result.expiryDate != null)
        _FieldEntry(
          AppStrings.expiryDate,
          result.expiryDate!,
          result.isFieldConfident('expiryDate'),
        ),
      if (result.registrationNo != null)
        _FieldEntry(
          AppStrings.registrationNo,
          result.registrationNo!,
          result.isFieldConfident('registrationNo'),
        ),
    ];

    // If only raw text, show it
    if (fields.isEmpty && result.rawText != null) {
      fields.add(_FieldEntry('Raw Text', result.rawText!, false));
    }

    return List.generate(fields.length, (index) {
      final field = fields[index];
      return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.itemSpacing),
            child: ExtractedFieldCard(
              fieldLabel: field.label,
              extractedValue: field.value,
              isConfident: field.isConfident,
            ),
          )
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: 200 + (index * 100)),
            duration: 400.ms,
          )
          .slideY(begin: 0.1, end: 0);
    });
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String message,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding * 1.5),
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
        children: [
          if (isLoading)
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primaryGreen,
              ),
            )
          else
            Icon(icon, size: 48, color: AppColors.primaryGreen),
          const SizedBox(height: AppDimensions.itemSpacing),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (isLoading) ...[
            const SizedBox(height: 8),
            Text(
              'Sandali lang...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'May problema sa OCR',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).shake(duration: 400.ms);
  }
}

class _FieldEntry {
  const _FieldEntry(this.label, this.value, this.isConfident);
  final String label;
  final String value;
  final bool isConfident;
}
