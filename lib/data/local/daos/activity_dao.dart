import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/activity_logs_table.dart';

part 'activity_dao.g.dart';

/// Data Access Object for ActivityLogs table.
///
/// Provides CRUD operations + sync helpers.
@DriftAccessor(tables: [ActivityLogs])
class ActivityDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityDaoMixin {
  ActivityDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  /// Watch all non-deleted activity logs ordered by date (newest first).
  Stream<List<ActivityLog>> watchAll() {
    return (select(activityLogs)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.desc(a.activityDate)]))
        .watch();
  }

  /// Get all non-deleted activity logs.
  Future<List<ActivityLog>> getAll() {
    return (select(activityLogs)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.desc(a.activityDate)]))
        .get();
  }

  /// Get a single activity by local ID.
  Future<ActivityLog?> getById(int localId) {
    return (select(
      activityLogs,
    )..where((a) => a.localId.equals(localId))).getSingleOrNull();
  }

  /// Get activity by remote Supabase ID.
  Future<ActivityLog?> getByRemoteId(String remoteId) {
    return (select(
      activityLogs,
    )..where((a) => a.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Get activities filtered by farm ID.
  Stream<List<ActivityLog>> watchByFarmId(String farmId) {
    return (select(activityLogs)
          ..where((a) => a.farmId.equals(farmId) & a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.desc(a.activityDate)]))
        .watch();
  }

  /// Count non-deleted activity logs.
  Future<int> countActivities() async {
    final query = selectOnly(activityLogs)
      ..where(activityLogs.isDeleted.equals(false))
      ..addColumns([activityLogs.localId.count()]);
    final result = await query.getSingle();
    return result.read(activityLogs.localId.count()) ?? 0;
  }

  // ── Write ────────────────────────────────────────────────────────

  /// Insert a new activity log (marked dirty for sync).
  Future<int> insertActivity(ActivityLogsCompanion log) {
    return into(activityLogs).insert(log);
  }

  /// Update an existing activity log, marking it dirty.
  Future<bool> updateActivity(int localId, ActivityLogsCompanion log) {
    return (update(activityLogs)..where((a) => a.localId.equals(localId)))
        .write(
          log.copyWith(
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Soft-delete an activity by local ID.
  Future<bool> softDelete(int localId) {
    return (update(activityLogs)..where((a) => a.localId.equals(localId)))
        .write(
          ActivityLogsCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ── Sync Helpers ─────────────────────────────────────────────────

  /// Get all records marked dirty.
  Future<List<ActivityLog>> getDirtyRecords() {
    return (select(activityLogs)..where((a) => a.isDirty.equals(true))).get();
  }

  /// Mark a record as synced.
  Future<void> markSynced(int localId, String remoteId) {
    return (update(
      activityLogs,
    )..where((a) => a.localId.equals(localId))).write(
      ActivityLogsCompanion(
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
      ),
    );
  }

  /// Upsert a record from Supabase (pull sync).
  Future<void> upsertFromRemote(ActivityLogsCompanion log) async {
    final remoteId = log.remoteId.value;
    if (remoteId == null) return;

    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        activityLogs,
      )..where((a) => a.localId.equals(existing.localId))).write(
        log.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(activityLogs).insert(
        log.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Hard-delete records that are both synced and soft-deleted.
  Future<int> purgeDeletedAndSynced() {
    return (delete(
      activityLogs,
    )..where((a) => a.isDeleted.equals(true) & a.isDirty.equals(false))).go();
  }
}
