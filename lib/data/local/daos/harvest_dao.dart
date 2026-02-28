import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/harvest_records_table.dart';

part 'harvest_dao.g.dart';

/// Data Access Object for HarvestRecords table.
@DriftAccessor(tables: [HarvestRecords])
class HarvestDao extends DatabaseAccessor<AppDatabase> with _$HarvestDaoMixin {
  HarvestDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  Stream<List<HarvestRecord>> watchAll(String userId) {
    return (select(harvestRecords)
          ..where((h) => h.isDeleted.equals(false) & h.userId.equals(userId))
          ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)]))
        .watch();
  }

  Future<List<HarvestRecord>> getAll(String userId) {
    return (select(harvestRecords)
          ..where((h) => h.isDeleted.equals(false) & h.userId.equals(userId))
          ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)]))
        .get();
  }

  Future<HarvestRecord?> getByRemoteId(String remoteId) {
    return (select(
      harvestRecords,
    )..where((h) => h.remoteId.equals(remoteId))).getSingleOrNull();
  }

  // ── Write ────────────────────────────────────────────────────────

  Future<int> insertRecord(HarvestRecordsCompanion record) {
    return into(harvestRecords).insert(record);
  }

  Future<bool> updateRecord(int localId, HarvestRecordsCompanion record) {
    return (update(harvestRecords)..where((h) => h.localId.equals(localId)))
        .write(
          record.copyWith(
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<bool> softDelete(int localId) {
    return (update(harvestRecords)..where((h) => h.localId.equals(localId)))
        .write(
          HarvestRecordsCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ── Sync Helpers ─────────────────────────────────────────────────

  Future<List<HarvestRecord>> getDirtyRecords() {
    return (select(harvestRecords)..where((h) => h.isDirty.equals(true))).get();
  }

  Future<void> markSynced(int localId, String remoteId) {
    return (update(
      harvestRecords,
    )..where((h) => h.localId.equals(localId))).write(
      HarvestRecordsCompanion(
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> upsertFromRemote(HarvestRecordsCompanion record) async {
    final remoteId = record.remoteId.value;
    if (remoteId == null) return;

    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        harvestRecords,
      )..where((h) => h.localId.equals(existing.localId))).write(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(harvestRecords).insert(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<int> purgeDeletedAndSynced() {
    return (delete(
      harvestRecords,
    )..where((h) => h.isDeleted.equals(true) & h.isDirty.equals(false))).go();
  }

  Future<int> deleteMissingRemoteIds(Set<String> validRemoteIds) {
    if (validRemoteIds.isEmpty) {
      return (delete(
        harvestRecords,
      )..where((h) => h.remoteId.isNotNull())).go();
    }
    return (delete(harvestRecords)..where(
          (h) => h.remoteId.isNotNull() & h.remoteId.isNotIn(validRemoteIds),
        ))
        .go();
  }
}
