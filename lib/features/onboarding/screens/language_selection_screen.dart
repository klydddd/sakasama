import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Language selection screen — second step of onboarding.
///
/// Presents 3 large toggle buttons: Filipino, Cebuano, English.
/// Selected language is persisted and used for all UI strings.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'Filipino';

  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      name: AppStrings.filipino,
      nativeName: 'Filipino',
      icon: '🇵🇭',
      description: 'Pambansang wika',
    ),
    _LanguageOption(
      name: AppStrings.cebuano,
      nativeName: 'Cebuano',
      icon: '🏝️',
      description: 'Bisaya',
    ),
    _LanguageOption(
      name: AppStrings.english,
      nativeName: 'English',
      icon: '🌐',
      description: 'International',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding'),
          tooltip: AppStrings.back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.itemSpacing),

              // ── Title ─────────────────────────────────────────────
              Text(
                AppStrings.selectLanguage,
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: AppDimensions.smallSpacing),

              Text(
                'Piliin ang wikang gusto mong gamitin sa app.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textGrey),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.sectionSpacing),

              // ── Language Options ──────────────────────────────────
              ...List.generate(_languages.length, (index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguage == lang.name;

                return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.itemSpacing,
                      ),
                      child: _buildLanguageTile(lang, isSelected),
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 300 + (index * 100)),
                      duration: 400.ms,
                    )
                    .slideX(begin: 0.1, end: 0);
              }),

              const Spacer(),

              // ── Next Button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppDimensions.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding/farm-setup'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppStrings.next),
                      const SizedBox(width: AppDimensions.smallSpacing),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.screenPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(_LanguageOption lang, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = lang.name),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.backgroundGreen : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : AppColors.divider,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // ── Flag Emoji ────────────────────────────────────
              Text(lang.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppDimensions.cardPadding),

              // ── Name & Description ────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.nativeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? AppColors.darkGreen
                            : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Check Icon ────────────────────────────────────
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.white,
                    size: 20,
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

class _LanguageOption {
  const _LanguageOption({
    required this.name,
    required this.nativeName,
    required this.icon,
    required this.description,
  });

  final String name;
  final String nativeName;
  final String icon;
  final String description;
}
