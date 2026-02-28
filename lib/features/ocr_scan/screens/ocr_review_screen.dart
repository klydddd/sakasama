import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/models/ocr_result.dart';
import 'package:sakasama/data/providers/ocr_providers.dart';
import 'package:sakasama/features/ocr_scan/widgets/extracted_field_card.dart';

/// OCR review screen showing extracted fields from a scanned image.
///
/// Classifies the scan as receipt / product / crop, shows type-specific
/// editable fields, and saves to the appropriate Supabase table on confirm.
class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  OcrResult? _editableResult;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset any stale state from a previous scan BEFORE processing
      _editableResult = null;
      ref.read(ocrInferenceProvider.notifier).reset();
      ref.read(ocrInferenceProvider.notifier).processImage(widget.imagePath);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _scanTypeLabel => switch (_editableResult?.scanType) {
    ScanType.receipt => 'Expenses Record',
    ScanType.product => 'Product Record',
    ScanType.crop => 'Harvesting Record',
    _ => 'Scanned Document',
  };

  Color get _scanTypeColor => switch (_editableResult?.scanType) {
    ScanType.receipt => AppColors.info,
    ScanType.product => AppColors.warning,
    ScanType.crop => AppColors.primaryGreen,
    _ => AppColors.textGrey,
  };

  Future<void> _saveToSupabase() async {
    if (_editableResult == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw StateError('Hindi naka-login.');

      switch (_editableResult!.scanType) {
        case ScanType.receipt:
          final date =
              _editableResult!.date ??
              DateTime.now().toIso8601String().split('T')[0];
          final supplier = _editableResult!.supplier;
          final photo = widget.imagePath;
          final items = _editableResult!.lineItems;

          if (items.isNotEmpty) {
            // Insert one row per line item
            for (final item in items) {
              await supabase.from('expense_records').insert({
                'user_id': userId,
                'expense_date': date,
                'description': item.description ?? 'Scanned receipt item',
                'quantity': _parseDouble(item.quantity),
                'unit': item.unit,
                'price_per_unit': _parseDouble(item.pricePerUnit),
                'total_value': _parseDouble(item.totalValue),
                'photo_path': photo,
                'notes': supplier != null ? 'Supplier: $supplier' : null,
                'updated_at': DateTime.now().toIso8601String(),
              });
            }
          } else {
            // Fallback: single row from flat fields
            await supabase.from('expense_records').insert({
              'user_id': userId,
              'expense_date': date,
              'description': _editableResult!.description ?? 'Scanned receipt',
              'quantity': _parseDouble(_editableResult!.quantity),
              'unit': _editableResult!.unit,
              'price_per_unit': _parseDouble(_editableResult!.pricePerUnit),
              'total_value': _parseDouble(_editableResult!.totalValue),
              'photo_path': photo,
              'notes': supplier != null ? 'Supplier: $supplier' : null,
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
          break;

        case ScanType.product:
          await supabase.from('product_records').insert({
            'user_id': userId,
            'product_name': _editableResult!.productName ?? 'Scanned product',
            'product_description': _editableResult!.productDescription,
            'manufacturer': _editableResult!.manufacturer,
            'net_weight': _editableResult!.netWeight,
            'expiration_date': _editableResult!.expirationDate,
            'category': _editableResult!.category ?? 'other',
            'photo_path': widget.imagePath,
            'updated_at': DateTime.now().toIso8601String(),
          });
          break;

        case ScanType.crop:
          await supabase.from('harvest_records').insert({
            'user_id': userId,
            'harvest_date': DateTime.now().toIso8601String().split('T')[0],
            'crop_name': _editableResult!.cropName ?? 'Scanned crop',
            'total_volume_kg': _parseDouble(_editableResult!.totalVolumeKg),
            'institutional_volume_kg': _parseDouble(
              _editableResult!.institutionalVolumeKg,
            ),
            'institutional_price_php': _parseDouble(
              _editableResult!.institutionalPricePhp,
            ),
            'other_volume_kg': _parseDouble(_editableResult!.otherVolumeKg),
            'other_price_php': _parseDouble(_editableResult!.otherPricePhp),
            'photo_path': widget.imagePath,
            'updated_at': DateTime.now().toIso8601String(),
          });
          break;

        case ScanType.unknown:
          // If unknown, save as expense by default
          await supabase.from('expense_records').insert({
            'user_id': userId,
            'expense_date': DateTime.now().toIso8601String().split('T')[0],
            'description':
                _editableResult!.rawText?.substring(0, 100) ?? 'Scanned item',
            'photo_path': widget.imagePath,
            'updated_at': DateTime.now().toIso8601String(),
          });
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Na-save na sa database!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _parseDouble(String? value) {
    if (value == null) return null;
    // Remove non-numeric chars except dot
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrInferenceProvider);

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
                // ── Image Preview ───────────────────────────────────
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

                // ── Processing States ───────────────────────────────
                if (ocrState.status == OcrStatus.processing)
                  _buildStatusCard(
                    icon: Icons.document_scanner_rounded,
                    message: AppStrings.processing,
                    isLoading: true,
                  ),

                if (ocrState.status == OcrStatus.error)
                  _buildErrorCard(ocrState.error ?? 'Unknown error'),

                // ── Success Content ─────────────────────────────────
                if (ocrState.status == OcrStatus.done &&
                    _editableResult != null) ...[
                  // Scan type badge
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.cardPadding),
                    decoration: BoxDecoration(
                      color: _scanTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.inputRadius,
                      ),
                      border: Border.all(
                        color: _scanTypeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          switch (_editableResult!.scanType) {
                            ScanType.receipt => Icons.receipt_long_rounded,
                            ScanType.product => Icons.inventory_2_rounded,
                            ScanType.crop => Icons.grass_rounded,
                            ScanType.unknown => Icons.help_outline_rounded,
                          },
                          color: _scanTypeColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scanTypeLabel,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _scanTypeColor,
                                    ),
                              ),
                              Text(
                                'Ise-save sa $_scanTypeLabel',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _scanTypeColor.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: AppDimensions.sectionSpacing),

                  // ── Type-specific fields ──────────────────────────
                  ..._buildFieldCards(),
                ],
              ],
            ),
          ),

          // ── Bottom Buttons ────────────────────────────────────────
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
                          onPressed: _isSaving ? null : _saveToSupabase,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSaving
                                ? 'Sine-save...'
                                : AppStrings.confirmAndSave,
                          ),
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
    final fields = <_FieldEntry>[];

    switch (result.scanType) {
      case ScanType.receipt:
        // Shared fields at the top
        if (result.date != null)
          fields.add(_FieldEntry('Petsa', result.date!, true));
        if (result.supplier != null)
          fields.add(_FieldEntry('Supplier', result.supplier!, true));

        if (result.hasMultipleItems) {
          // Multi-item: show shared fields first, then grouped item cards
          if (result.totalValue != null)
            fields.add(
              _FieldEntry('Kabuuang Halaga (Lahat)', result.totalValue!, true),
            );

          // Build shared field widgets
          final widgets = <Widget>[];
          for (int i = 0; i < fields.length; i++) {
            final field = fields[i];
            widgets.add(
              Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.itemSpacing,
                    ),
                    child: ExtractedFieldCard(
                      fieldLabel: field.label,
                      extractedValue: field.value,
                      isConfident: field.isConfident,
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 200 + (i * 100)),
                    duration: 400.ms,
                  )
                  .slideY(begin: 0.1, end: 0),
            );
          }

          // Add a divider and label
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, size: 20, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    '${result.lineItems.length} na item sa resibo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 200 + (fields.length * 100)),
            ),
          );

          // Add grouped item cards
          for (int idx = 0; idx < result.lineItems.length; idx++) {
            final item = result.lineItems[idx];
            final animDelay = Duration(
              milliseconds: 400 + (fields.length * 100) + (idx * 120),
            );
            widgets.add(
              Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.cardRadius,
                      ),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
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
                        // Item header
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.info,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.description ?? 'Item ${idx + 1}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (item.totalValue != null)
                              Text(
                                '₱${item.totalValue}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryGreen,
                                    ),
                              ),
                          ],
                        ),
                        // Item details
                        if (item.quantity != null ||
                            item.unit != null ||
                            item.pricePerUnit != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (item.quantity != null) ...[
                                Text(
                                  'Dami: ${item.quantity}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMedium),
                                ),
                                const SizedBox(width: 16),
                              ],
                              if (item.unit != null)
                                Text(
                                  'Yunit: ${item.unit}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMedium),
                                ),
                              if (item.pricePerUnit != null) ...[
                                const SizedBox(width: 16),
                                Text(
                                  '₱${item.pricePerUnit}/unit',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMedium),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: animDelay, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
            );
          }

          return widgets;
        } else {
          // Single item — flat layout (backward compatible)
          if (result.lineItems.isNotEmpty) {
            final item = result.lineItems.first;
            if (item.description != null)
              fields.add(
                _FieldEntry('Deskripsyon / Input', item.description!, true),
              );
            if (item.quantity != null)
              fields.add(_FieldEntry('Dami', item.quantity!, true));
            if (item.unit != null)
              fields.add(_FieldEntry('Yunit', item.unit!, true));
            if (item.pricePerUnit != null)
              fields.add(
                _FieldEntry('Presyo Bawat Yunit', item.pricePerUnit!, true),
              );
            if (item.totalValue != null)
              fields.add(
                _FieldEntry('Kabuuang Halaga', item.totalValue!, true),
              );
          } else {
            // Legacy fallback from flat fields
            if (result.description != null)
              fields.add(
                _FieldEntry('Deskripsyon / Input', result.description!, true),
              );
            if (result.quantity != null)
              fields.add(_FieldEntry('Dami', result.quantity!, true));
            if (result.unit != null)
              fields.add(_FieldEntry('Yunit', result.unit!, true));
            if (result.pricePerUnit != null)
              fields.add(
                _FieldEntry('Presyo Bawat Yunit', result.pricePerUnit!, true),
              );
            if (result.totalValue != null)
              fields.add(
                _FieldEntry('Kabuuang Halaga', result.totalValue!, true),
              );
          }
        }
        break;

      case ScanType.product:
        if (result.productName != null)
          fields.add(
            _FieldEntry('Pangalan ng Produkto', result.productName!, true),
          );
        if (result.productDescription != null)
          fields.add(
            _FieldEntry('Deskripsyon', result.productDescription!, true),
          );
        if (result.manufacturer != null)
          fields.add(_FieldEntry('Manufacturer', result.manufacturer!, true));
        if (result.netWeight != null)
          fields.add(_FieldEntry('Net Weight', result.netWeight!, true));
        if (result.expirationDate != null)
          fields.add(
            _FieldEntry('Expiration Date', result.expirationDate!, true),
          );
        if (result.category != null)
          fields.add(_FieldEntry('Kategorya', result.category!, true));
        break;

      case ScanType.crop:
        if (result.cropName != null)
          fields.add(_FieldEntry('Uri ng Ani', result.cropName!, true));
        if (result.totalVolumeKg != null)
          fields.add(
            _FieldEntry('Kabuuang Timbang (KG)', result.totalVolumeKg!, true),
          );
        if (result.institutionalVolumeKg != null)
          fields.add(
            _FieldEntry(
              'Institutional Market - Volume (KG)',
              result.institutionalVolumeKg!,
              true,
            ),
          );
        if (result.institutionalPricePhp != null)
          fields.add(
            _FieldEntry(
              'Institutional Market - Presyo (PHP)',
              result.institutionalPricePhp!,
              true,
            ),
          );
        if (result.otherVolumeKg != null)
          fields.add(
            _FieldEntry(
              'Other Market - Volume (KG)',
              result.otherVolumeKg!,
              true,
            ),
          );
        if (result.otherPricePhp != null)
          fields.add(
            _FieldEntry(
              'Other Market - Presyo (PHP)',
              result.otherPricePhp!,
              true,
            ),
          );
        break;

      case ScanType.unknown:
        if (result.rawText != null)
          fields.add(_FieldEntry('Raw Text', result.rawText!, false));
        break;
    }

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
              'Sinusuri ang larawan...',
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
                  'May problema sa pag-scan',
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
