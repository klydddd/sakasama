import 'package:sakasama/data/local/daos/activity_dao.dart';
import 'package:sakasama/data/local/daos/expense_dao.dart';
import 'package:sakasama/data/local/daos/farm_dao.dart';
import 'package:sakasama/data/local/daos/harvest_dao.dart';
import 'package:sakasama/data/local/daos/product_dao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds a text summary of the user's farm data for RAG context injection.
///
/// Queries the local Drift database for recent records and returns
/// a formatted string that can be prepended to Gemini chat prompts.
class FarmDataContext {
  FarmDataContext({
    required this.farmDao,
    required this.activityDao,
    required this.expenseDao,
    required this.harvestDao,
    required this.productDao,
  });

  final FarmDao farmDao;
  final ActivityDao activityDao;
  final ExpenseDao expenseDao;
  final HarvestDao harvestDao;
  final ProductDao productDao;

  /// Build the full context string from all data sources.
  ///
  /// Limits each category to the 20 most recent records to avoid
  /// exceeding Gemini's context window.
  Future<String> buildContext() async {
    final buffer = StringBuffer();
    buffer.writeln('=== MGA DATOS NG MAGSASAKA (FARM DATA) ===');
    buffer.writeln(
      'Gamitin ang mga datos na ito para sagutin ang tanong ng user.',
    );
    buffer.writeln();

    await _addFarmProfile(buffer);
    await _addProducts(buffer);
    await _addExpenses(buffer);
    await _addHarvests(buffer);
    await _addActivities(buffer);

    buffer.writeln('=== DULO NG DATOS ===');
    return buffer.toString();
  }

  Future<void> _addFarmProfile(StringBuffer buf) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id ?? '';
      final farms = await farmDao.getAll(userId);
      if (farms.isEmpty) return;

      buf.writeln('## Farm Profile');
      for (final farm in farms) {
        buf.writeln('- Pangalan: ${farm.farmName}');
        buf.writeln('  Magsasaka: ${farm.farmerName}');
        if (farm.location != null) buf.writeln('  Lokasyon: ${farm.location}');
        if (farm.cropType != null)
          buf.writeln('  Uri ng pananim: ${farm.cropType}');
        if (farm.farmSizeHectares != null) {
          buf.writeln('  Laki: ${farm.farmSizeHectares} hectares');
        }
      }
      buf.writeln();
    } catch (_) {}
  }

  Future<void> _addProducts(StringBuffer buf) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id ?? '';
      final products = await productDao.getAll(userId);
      if (products.isEmpty) return;

      final limited = products.take(20).toList();
      buf.writeln('## Mga Produkto (${products.length} records)');
      for (final p in limited) {
        final parts = <String>[p.productName];
        if (p.category != null) parts.add('(${p.category})');
        if (p.manufacturer != null) parts.add('- ${p.manufacturer}');
        if (p.netWeight != null) parts.add('- ${p.netWeight}');
        if (p.expirationDate != null) {
          parts.add(
            '- exp ${p.expirationDate!.toIso8601String().split('T')[0]}',
          );
        }
        if (p.productDescription != null)
          parts.add('- ${p.productDescription}');
        buf.writeln('- ${parts.join(' ')}');
      }
      buf.writeln();
    } catch (_) {}
  }

  Future<void> _addExpenses(StringBuffer buf) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id ?? '';
      final expenses = await expenseDao.getAll(userId);
      if (expenses.isEmpty) return;

      final limited = expenses.take(20).toList();
      double totalExpenses = 0;
      for (final e in expenses) {
        if (e.totalValue != null) totalExpenses += e.totalValue!;
      }

      buf.writeln(
        '## Mga Gastos / Expenses (${expenses.length} records, Kabuuan: ₱${totalExpenses.toStringAsFixed(2)})',
      );
      for (final e in limited) {
        final date = e.expenseDate.toIso8601String().split('T')[0];
        final parts = <String>[date, e.description];
        if (e.quantity != null && e.unit != null) {
          parts.add('${e.quantity} ${e.unit}');
        }
        if (e.pricePerUnit != null) parts.add('₱${e.pricePerUnit}/unit');
        if (e.totalValue != null)
          parts.add('Kabuuan: ₱${e.totalValue!.toStringAsFixed(2)}');
        buf.writeln('- ${parts.join(' | ')}');
      }
      buf.writeln();
    } catch (_) {}
  }

  Future<void> _addHarvests(StringBuffer buf) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id ?? '';
      final harvests = await harvestDao.getAll(userId);
      if (harvests.isEmpty) return;

      final limited = harvests.take(20).toList();
      double totalKg = 0;
      for (final h in harvests) {
        if (h.totalVolumeKg != null) totalKg += h.totalVolumeKg!;
      }

      buf.writeln(
        '## Mga Ani / Harvests (${harvests.length} records, Kabuuang timbang: ${totalKg.toStringAsFixed(1)} kg)',
      );
      for (final h in limited) {
        final date = h.harvestDate.toIso8601String().split('T')[0];
        final parts = <String>[date, h.cropName];
        if (h.totalVolumeKg != null) parts.add('${h.totalVolumeKg} kg');
        if (h.institutionalVolumeKg != null &&
            h.institutionalPricePhp != null) {
          parts.add(
            'Institutional: ${h.institutionalVolumeKg}kg @ ₱${h.institutionalPricePhp}',
          );
        }
        if (h.otherVolumeKg != null && h.otherPricePhp != null) {
          parts.add('Other: ${h.otherVolumeKg}kg @ ₱${h.otherPricePhp}');
        }
        buf.writeln('- ${parts.join(' | ')}');
      }
      buf.writeln();
    } catch (_) {}
  }

  Future<void> _addActivities(StringBuffer buf) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id ?? '';
      final activities = await activityDao.getAll(userId);
      if (activities.isEmpty) return;

      final limited = activities.take(20).toList();
      buf.writeln(
        '## Mga Aktibidad / Activities (${activities.length} records)',
      );
      for (final a in limited) {
        final date = a.activityDate.toIso8601String().split('T')[0];
        final parts = <String>[date, a.activityType];
        if (a.productUsed != null) parts.add('Ginamit: ${a.productUsed}');
        if (a.quantity != null && a.unit != null) {
          parts.add('${a.quantity} ${a.unit}');
        }
        if (a.notes != null) parts.add('Notes: ${a.notes}');
        buf.writeln('- ${parts.join(' | ')}');
      }
      buf.writeln();
    } catch (_) {}
  }
}
