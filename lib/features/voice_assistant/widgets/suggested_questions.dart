import 'package:flutter/material.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Horizontal scroll of sample question chips shown in the voice assistant.
class SuggestedQuestions extends StatelessWidget {
  const SuggestedQuestions({super.key, this.onQuestionTap});

  final ValueChanged<String>? onQuestionTap;

  static const List<String> _questions = [
    AppStrings.sampleQuestion1,
    AppStrings.sampleQuestion2,
    AppStrings.sampleQuestion3,
    AppStrings.sampleQuestion4,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.screenPadding,
            bottom: AppDimensions.smallSpacing,
          ),
          child: Text(
            'Mga Mungkahing Tanong:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
            ),
            itemCount: _questions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final question = _questions[index];
              return ActionChip(
                label: Text(
                  question,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.backgroundGreen,
                side: const BorderSide(color: AppColors.lightGreen, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
                ),
                onPressed: () => onQuestionTap?.call(question),
              );
            },
          ),
        ),
      ],
    );
  }
}
