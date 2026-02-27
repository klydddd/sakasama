import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Activity entry form screen for logging farm activities.
///
/// Large input fields (18sp+) with Filipino labels.
/// Fields: date, activity type, product, quantity, unit, notes, photo.
class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedActivityType;
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedUnit;
  final _notesController = TextEditingController();

  static const List<String> _activityTypes = [
    AppStrings.fertilization,
    AppStrings.irrigation,
    AppStrings.pestControl,
    AppStrings.harvest,
    AppStrings.planting,
    AppStrings.pruning,
    AppStrings.soilPrep,
    AppStrings.other,
  ];

  static const List<String> _units = [
    'kg',
    'g',
    'L',
    'mL',
    'sako (sack)',
    'piraso (piece)',
    'tasa (cup)',
  ];

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(AppStrings.logActivity),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date Picker ─────────────────────────────────────────
              _buildLabel(
                context,
                AppStrings.date,
                Icons.calendar_today_rounded,
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.inputRadius,
                    ),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: AppDimensions.smallSpacing),
                      Text(
                        '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: AppDimensions.itemSpacing * 1.5),

              // ── Activity Type ───────────────────────────────────────
              _buildLabel(
                context,
                AppStrings.activityType,
                Icons.category_rounded,
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              DropdownButtonFormField<String>(
                value: _selectedActivityType,
                decoration: const InputDecoration(
                  hintText: 'Pumili ng aktibidad',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                items: _activityTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedActivityType = value);
                },
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.itemSpacing * 1.5),

              // ── Product Used ────────────────────────────────────────
              _buildLabel(
                context,
                AppStrings.productUsed,
                Icons.inventory_2_rounded,
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              TextFormField(
                controller: _productController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(hintText: 'e.g. Urea 46-0-0'),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.itemSpacing * 1.5),

              // ── Quantity & Unit Row ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          context,
                          AppStrings.quantity,
                          Icons.straighten_rounded,
                        ),
                        const SizedBox(height: AppDimensions.smallSpacing),
                        TextFormField(
                          controller: _quantityController,
                          style: Theme.of(context).textTheme.bodyLarge,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 5'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.itemSpacing),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          context,
                          AppStrings.unit,
                          Icons.scale_rounded,
                        ),
                        const SizedBox(height: AppDimensions.smallSpacing),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(hintText: 'Yunit'),
                          style: Theme.of(context).textTheme.bodyLarge,
                          items: _units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedUnit = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.itemSpacing * 1.5),

              // ── Notes ───────────────────────────────────────────────
              _buildLabel(context, AppStrings.notes, Icons.notes_rounded),
              const SizedBox(height: AppDimensions.smallSpacing),
              TextFormField(
                controller: _notesController,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Mga karagdagang detalye...',
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.itemSpacing * 1.5),

              // ── Photo Button ────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  // Will connect to camera/gallery later
                },
                icon: const Icon(Icons.add_a_photo_rounded),
                label: Text(AppStrings.addPhoto),
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.sectionSpacing),

              // ── Save Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppDimensions.primaryButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Save to database in future
                    context.pop();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(AppStrings.save),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
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
