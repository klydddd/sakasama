import 'package:drift/drift.dart';
import 'package:sakasama/data/local/daos/activity_dao.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/core/services/sync_service.dart';

/// Repository for activity log data.
///
/// Reads always come from the local SQLite database.
/// Writes go to local DB first (marked dirty), then trigger sync.
class ActivityRepository {
  ActivityRepository({required this.activityDao, required this.syncService});

  final ActivityDao activityDao;
  final SyncService syncService;

  /// Watch all activities (reactive stream).
  Stream<List<ActivityLog>> watchAll() => activityDao.watchAll();

  /// Get all activities (one-shot).
  Future<List<ActivityLog>> getAll() => activityDao.getAll();

  /// Watch activities for a specific farm.
  Stream<List<ActivityLog>> watchByFarm(String farmId) =>
      activityDao.watchByFarmId(farmId);

  /// Get a single activity by ID.
  Future<ActivityLog?> getById(int localId) => activityDao.getById(localId);

  /// Create a new activity log entry.
  Future<int> create({
    required DateTime activityDate,
    required String activityType,
    String? productUsed,
    double? quantity,
    String? unit,
    String? notes,
    String? photoPath,
    String? farmId,
    String? userId,
  }) async {
    final id = await activityDao.insertActivity(
      ActivityLogsCompanion.insert(
        activityDate: activityDate,
        activityType: activityType,
        productUsed: Value(productUsed),
        quantity: Value(quantity),
        unit: Value(unit),
        notes: Value(notes),
        photoPath: Value(photoPath),
        farmId: Value(farmId),
        userId: Value(userId),
      ),
    );

    syncService.syncAll();
    return id;
  }

  /// Update an existing activity log.
  Future<bool> update(
    int localId, {
    DateTime? activityDate,
    String? activityType,
    String? productUsed,
    double? quantity,
    String? unit,
    String? notes,
    String? photoPath,
  }) async {
    final result = await activityDao.updateActivity(
      localId,
      ActivityLogsCompanion(
        activityDate: activityDate != null
            ? Value(activityDate)
            : const Value.absent(),
        activityType: activityType != null
            ? Value(activityType)
            : const Value.absent(),
        productUsed: productUsed != null
            ? Value(productUsed)
            : const Value.absent(),
        quantity: quantity != null ? Value(quantity) : const Value.absent(),
        unit: unit != null ? Value(unit) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        photoPath: photoPath != null ? Value(photoPath) : const Value.absent(),
      ),
    );

    syncService.syncAll();
    return result;
  }

  /// Soft-delete an activity.
  Future<void> delete(int localId) async {
    await activityDao.softDelete(localId);
    syncService.syncAll();
  }
}
