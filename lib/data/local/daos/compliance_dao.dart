import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/compliance_records_table.dart';

part 'compliance_dao.g.dart';

/// Data Access Object for ComplianceRecords table.
///
/// Provides CRUD operations + sync helpers.
@DriftAccessor(tables: [ComplianceRecords])
class ComplianceDao extends DatabaseAccessor<AppDatabase>
    with _$ComplianceDaoMixin {
  ComplianceDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  /// Watch all non-deleted compliance records.
  Stream<List<ComplianceRecord>> watchAll() {
    return (select(complianceRecords)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .watch();
  }

  /// Get all non-deleted compliance records.
  Future<List<ComplianceRecord>> getAll() {
    return (select(complianceRecords)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .get();
  }

  /// Get a single record by local ID.
  Future<ComplianceRecord?> getById(int localId) {
    return (select(
      complianceRecords,
    )..where((c) => c.localId.equals(localId))).getSingleOrNull();
  }

  /// Get record by remote Supabase ID.
  Future<ComplianceRecord?> getByRemoteId(String remoteId) {
    return (select(
      complianceRecords,
    )..where((c) => c.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Watch records filtered by form type.
  Stream<List<ComplianceRecord>> watchByFormType(String formType) {
    return (select(complianceRecords)
          ..where(
            (c) => c.formType.equals(formType) & c.isDeleted.equals(false),
          )
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .watch();
  }

  // ── Write ────────────────────────────────────────────────────────

  /// Insert a new compliance record (marked dirty for sync).
  Future<int> insertRecord(ComplianceRecordsCompanion record) {
    return into(complianceRecords).insert(record);
  }

  /// Update an existing compliance record, marking it dirty.
  Future<bool> updateRecord(int localId, ComplianceRecordsCompanion record) {
    return (update(complianceRecords)..where((c) => c.localId.equals(localId)))
        .write(
          record.copyWith(
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Soft-delete a record by local ID.
  Future<bool> softDelete(int localId) {
    return (update(complianceRecords)..where((c) => c.localId.equals(localId)))
        .write(
          ComplianceRecordsCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ── Sync Helpers ─────────────────────────────────────────────────

  /// Get all records marked dirty.
  Future<List<ComplianceRecord>> getDirtyRecords() {
    return (select(
      complianceRecords,
    )..where((c) => c.isDirty.equals(true))).get();
  }

  /// Mark a record as synced.
  Future<void> markSynced(int localId, String remoteId) {
    return (update(
      complianceRecords,
    )..where((c) => c.localId.equals(localId))).write(
      ComplianceRecordsCompanion(
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
      ),
    );
  }

  /// Upsert a record from Supabase (pull sync).
  Future<void> upsertFromRemote(ComplianceRecordsCompanion record) async {
    final remoteId = record.remoteId.value;
    if (remoteId == null) return;

    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        complianceRecords,
      )..where((c) => c.localId.equals(existing.localId))).write(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(complianceRecords).insert(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Hard-delete records that are both synced and soft-deleted.
  Future<int> purgeDeletedAndSynced() {
    return (delete(
      complianceRecords,
    )..where((c) => c.isDeleted.equals(true) & c.isDirty.equals(false))).go();
  }
}
