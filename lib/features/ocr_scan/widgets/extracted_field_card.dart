import 'package:flutter/material.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';

/// Card showing an extracted OCR field with editable value
/// and confidence badge (green ✅ or yellow ⚠️).
class ExtractedFieldCard extends StatelessWidget {
  const ExtractedFieldCard({
    super.key,
    required this.fieldLabel,
    required this.extractedValue,
    required this.isConfident,
    this.onChanged,
  });

  final String fieldLabel;
  final String extractedValue;
  final bool isConfident;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isConfident ? AppColors.success : AppColors.warning,
          width: 1.5,
        ),
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
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                isConfident
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                color: isConfident ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                fieldLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isConfident
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
                ),
                child: Text(
                  isConfident ? 'Nakita' : 'Hindi sigurado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isConfident ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.smallSpacing),

          // ── Editable Value ──────────────────────────────────────────
          TextFormField(
            initialValue: extractedValue,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
