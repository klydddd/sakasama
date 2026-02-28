import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/farm_profiles_table.dart';

part 'farm_dao.g.dart';

/// Data Access Object for FarmProfiles table.
///
/// Provides CRUD operations + sync helpers (dirty records, upsert from remote).
@DriftAccessor(tables: [FarmProfiles])
class FarmDao extends DatabaseAccessor<AppDatabase> with _$FarmDaoMixin {
  FarmDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  /// Watch all non-deleted farm profiles.
  Stream<List<FarmProfile>> watchAll(String userId) {
    return (select(farmProfiles)
          ..where((f) => f.isDeleted.equals(false) & f.userId.equals(userId))
          ..orderBy([(f) => OrderingTerm.desc(f.updatedAt)]))
        .watch();
  }

  /// Get all non-deleted farm profiles.
  Future<List<FarmProfile>> getAll(String userId) {
    return (select(farmProfiles)
          ..where((f) => f.isDeleted.equals(false) & f.userId.equals(userId))
          ..orderBy([(f) => OrderingTerm.desc(f.updatedAt)]))
        .get();
  }

  /// Get a single farm by local ID.
  Future<FarmProfile?> getById(int localId) {
    return (select(
      farmProfiles,
    )..where((f) => f.localId.equals(localId))).getSingleOrNull();
  }

  /// Get farm by remote Supabase ID.
  Future<FarmProfile?> getByRemoteId(String remoteId) {
    return (select(
      farmProfiles,
    )..where((f) => f.remoteId.equals(remoteId))).getSingleOrNull();
  }

  // ── Write ────────────────────────────────────────────────────────

  /// Insert a new farm profile (marked dirty for sync).
  Future<int> insertFarm(FarmProfilesCompanion farm) {
    return into(farmProfiles).insert(farm);
  }

  /// Update an existing farm profile, marking it dirty.
  Future<bool> updateFarm(int localId, FarmProfilesCompanion farm) {
    return (update(farmProfiles)..where((f) => f.localId.equals(localId)))
        .write(
          farm.copyWith(
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Soft-delete a farm by local ID.
  Future<bool> softDelete(int localId) {
    return (update(farmProfiles)..where((f) => f.localId.equals(localId)))
        .write(
          FarmProfilesCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ── Sync Helpers ─────────────────────────────────────────────────

  /// Get all records marked dirty (need to be pushed to Supabase).
  Future<List<FarmProfile>> getDirtyRecords() {
    return (select(farmProfiles)..where((f) => f.isDirty.equals(true))).get();
  }

  /// Mark a record as synced (no longer dirty).
  Future<void> markSynced(int localId, String remoteId) {
    return (update(
      farmProfiles,
    )..where((f) => f.localId.equals(localId))).write(
      FarmProfilesCompanion(
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
      ),
    );
  }

  /// Upsert a record from Supabase (pull sync).
  /// If a record with the same remoteId exists, update it.
  /// Otherwise, insert it.
  Future<void> upsertFromRemote(FarmProfilesCompanion farm) async {
    final remoteId = farm.remoteId.value;
    if (remoteId == null) return;

    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        farmProfiles,
      )..where((f) => f.localId.equals(existing.localId))).write(
        farm.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(farmProfiles).insert(
        farm.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Hard-delete records that are both synced and soft-deleted.
  Future<int> purgeDeletedAndSynced() {
    return (delete(
      farmProfiles,
    )..where((f) => f.isDeleted.equals(true) & f.isDirty.equals(false))).go();
  }

  /// Delete local records that were hard-deleted on the remote server.
  Future<int> deleteMissingRemoteIds(Set<String> validRemoteIds) {
    if (validRemoteIds.isEmpty) {
      return (delete(farmProfiles)..where((f) => f.remoteId.isNotNull())).go();
    }
    return (delete(farmProfiles)..where(
          (f) => f.remoteId.isNotNull() & f.remoteId.isNotIn(validRemoteIds),
        ))
        .go();
  }
}
