import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/database_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Detail view of a compliance form type showing real records from the database.
class FormDetailScreen extends ConsumerWidget {
  const FormDetailScreen({super.key, required this.formType});

  final String formType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceDao = ref.watch(complianceDaoProvider);
    final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(formType.isNotEmpty ? formType : 'Form Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<ComplianceRecord>>(
        stream: complianceDao.watchByFormType(formType, userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];
          final isComplete = records.any((r) => r.status == 'complete');

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Badge ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.cardPadding),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isComplete
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: isComplete
                            ? AppColors.success
                            : AppColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isComplete
                                  ? AppStrings.statusComplete
                                  : AppStrings.statusIncomplete,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isComplete
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${records.length} record${records.length != 1 ? 's' : ''} na-save',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isComplete
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: AppDimensions.sectionSpacing),

                // ── Records List ──────────────────────────────────
                if (records.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: AppDimensions.cardPadding,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.cardRadius,
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
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: AppColors.textGrey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Walang record pa',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mag-scan o mag-log ng aktibidad para makapag-save dito.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms)
                else
                  ...records.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
                    return _buildRecordCard(context, record, dateFormat, index);
                  }),

                const SizedBox(height: AppDimensions.sectionSpacing),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    ComplianceRecord record,
    DateFormat dateFormat,
    int index,
  ) {
    // Parse the JSON data field
    Map<String, dynamic> dataMap = {};
    try {
      dataMap = jsonDecode(record.data) as Map<String, dynamic>;
    } catch (_) {}

    final fields = <_FormField>[];

    // Always show status & dates
    fields.add(_FormField('Status', record.status));
    fields.add(_FormField('Na-save', dateFormat.format(record.createdAt)));
    fields.add(
      _FormField('Huling Update', dateFormat.format(record.updatedAt)),
    );

    if (record.submittedAt != null) {
      fields.add(
        _FormField('Na-submit', dateFormat.format(record.submittedAt!)),
      );
    }

    // Show all data fields from the JSON
    for (final entry in dataMap.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        fields.add(_FormField(_formatKey(entry.key), entry.value.toString()));
      }
    }

    return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.itemSpacing),
          child: Container(
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
                // Record header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: record.status == 'complete'
                            ? AppColors.successLight
                            : AppColors.warningLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: record.status == 'complete'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Record #${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: record.status == 'complete'
                            ? AppColors.successLight
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.chipRadius,
                        ),
                      ),
                      child: Text(
                        record.status == 'complete'
                            ? AppStrings.statusComplete
                            : AppStrings.statusIncomplete,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: record.status == 'complete'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Data fields
                ...fields
                    .skip(1)
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(
                                field.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                field.value,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 200 + (index * 100)),
          duration: 400.ms,
        )
        .slideY(begin: 0.05, end: 0);
  }

  /// Convert snake_case keys to readable labels.
  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}

class _FormField {
  const _FormField(this.label, this.value);
  final String label;
  final String value;
}
