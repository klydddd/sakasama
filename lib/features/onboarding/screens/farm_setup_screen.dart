import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Farm profile setup screen — third step of onboarding.
///
/// Collects farmer name, farm name, location, and crop type.
/// Saves the profile to the local SQLite database on submit.
class FarmSetupScreen extends ConsumerStatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  ConsumerState<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends ConsumerState<FarmSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmerNameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCropType;
  bool _isSaving = false;

  static const List<String> _cropTypes = [
    'Palay (Rice)',
    'Mais (Corn)',
    'Gulay (Vegetables)',
    'Prutas (Fruits)',
    'Niyog (Coconut)',
    'Tubo (Sugarcane)',
    'Kape (Coffee)',
    'Iba pa (Other)',
  ];

  @override
  void dispose() {
    _farmerNameController.dispose();
    _farmNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveFarmProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;

      await ref
          .read(farmRepositoryProvider)
          .create(
            farmerName: _farmerNameController.text.trim(),
            farmName: _farmNameController.text.trim(),
            location: _locationController.text.trim().isNotEmpty
                ? _locationController.text.trim()
                : null,
            cropType: _selectedCropType,
            userId: userId,
          );

      if (mounted) {
        context.go('/onboarding/permissions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('May problema sa pag-save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding/language'),
          tooltip: AppStrings.back,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.itemSpacing),

                // ── Title ─────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.itemSpacing),
                    Expanded(
                      child: Text(
                        AppStrings.setupFarm,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: AppDimensions.smallSpacing),

                Text(
                  'Ilagay ang impormasyon tungkol sa iyong bukid.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textGrey),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: AppDimensions.sectionSpacing),

                // ── Farmer Name ───────────────────────────────────────
                _buildFieldLabel(
                  context,
                  AppStrings.farmerName,
                  Icons.person_rounded,
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                TextFormField(
                  controller: _farmerNameController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Juan Dela Cruz',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ilagay ang pangalan ng magsasaka';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: AppDimensions.itemSpacing * 1.5),

                // ── Farm Name ─────────────────────────────────────────
                _buildFieldLabel(
                  context,
                  AppStrings.farmName,
                  Icons.landscape_rounded,
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                TextFormField(
                  controller: _farmNameController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Bukid ni Juan',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ilagay ang pangalan ng bukid';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: AppDimensions.itemSpacing * 1.5),

                // ── Location ──────────────────────────────────────────
                _buildFieldLabel(
                  context,
                  AppStrings.location,
                  Icons.location_on_rounded,
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                TextFormField(
                  controller: _locationController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Laguna, Los Baños',
                  ),
                  textCapitalization: TextCapitalization.words,
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppDimensions.itemSpacing * 1.5),

                // ── Crop Type ─────────────────────────────────────────
                _buildFieldLabel(
                  context,
                  AppStrings.cropType,
                  Icons.grass_rounded,
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                DropdownButtonFormField<String>(
                  value: _selectedCropType,
                  decoration: const InputDecoration(
                    hintText: 'Pumili ng uri ng pananim',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  items: _cropTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCropType = value);
                  },
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: AppDimensions.sectionSpacing * 1.5),

                // ── Save & Continue Button ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.primaryButtonHeight,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFarmProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppStrings.next),
                              const SizedBox(width: AppDimensions.smallSpacing),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                const SizedBox(height: AppDimensions.sectionSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: AppDimensions.smallSpacing),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
