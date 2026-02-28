import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/core/services/auth_service.dart';
import 'package:sakasama/core/services/connectivity_service.dart';
import 'package:sakasama/core/services/sync_service.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/daos/farm_dao.dart';
import 'package:sakasama/data/local/daos/activity_dao.dart';
import 'package:sakasama/data/local/daos/compliance_dao.dart';
import 'package:sakasama/data/local/daos/expense_dao.dart';
import 'package:sakasama/data/local/daos/harvest_dao.dart';
import 'package:sakasama/data/local/daos/product_dao.dart';
import 'package:sakasama/data/local/daos/user_profile_dao.dart';
import 'package:sakasama/data/repositories/farm_repository.dart';
import 'package:sakasama/data/repositories/activity_repository.dart';
import 'package:sakasama/data/repositories/compliance_repository.dart';

// ── Database ──────────────────────────────────────────────────────────

/// Singleton local SQLite database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ── DAOs ──────────────────────────────────────────────────────────────

final userProfileDaoProvider = Provider<UserProfileDao>((ref) {
  return ref.watch(databaseProvider).userProfileDao;
});

final farmDaoProvider = Provider<FarmDao>((ref) {
  return ref.watch(databaseProvider).farmDao;
});

final activityDaoProvider = Provider<ActivityDao>((ref) {
  return ref.watch(databaseProvider).activityDao;
});

final complianceDaoProvider = Provider<ComplianceDao>((ref) {
  return ref.watch(databaseProvider).complianceDao;
});

final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  return ref.watch(databaseProvider).expenseDao;
});

final harvestDaoProvider = Provider<HarvestDao>((ref) {
  return ref.watch(databaseProvider).harvestDao;
});

final productDaoProvider = Provider<ProductDao>((ref) {
  return ref.watch(databaseProvider).productDao;
});

// ── Services ──────────────────────────────────────────────────────────

/// Supabase client singleton.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth service.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Connectivity monitoring service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Sync service (auto-triggers on reconnection).
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    supabase: ref.watch(supabaseClientProvider),
    farmDao: ref.watch(farmDaoProvider),
    activityDao: ref.watch(activityDaoProvider),
    complianceDao: ref.watch(complianceDaoProvider),
    expenseDao: ref.watch(expenseDaoProvider),
    harvestDao: ref.watch(harvestDaoProvider),
    productDao: ref.watch(productDaoProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Repositories ──────────────────────────────────────────────────────

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepository(
    farmDao: ref.watch(farmDaoProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(
    activityDao: ref.watch(activityDaoProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

final complianceRepositoryProvider = Provider<ComplianceRepository>((ref) {
  return ComplianceRepository(
    complianceDao: ref.watch(complianceDaoProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});
