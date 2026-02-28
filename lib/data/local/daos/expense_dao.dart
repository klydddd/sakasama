import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/expense_records_table.dart';

part 'expense_dao.g.dart';

/// Data Access Object for ExpenseRecords table.
@DriftAccessor(tables: [ExpenseRecords])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  Stream<List<ExpenseRecord>> watchAll(String userId) {
    return (select(expenseRecords)
          ..where((e) => e.isDeleted.equals(false) & e.userId.equals(userId))
          ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
        .watch();
  }

  Future<List<ExpenseRecord>> getAll(String userId) {
    return (select(expenseRecords)
          ..where((e) => e.isDeleted.equals(false) & e.userId.equals(userId))
          ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
        .get();
  }

  Future<ExpenseRecord?> getByRemoteId(String remoteId) {
    return (select(
      expenseRecords,
    )..where((e) => e.remoteId.equals(remoteId))).getSingleOrNull();
  }

  // ── Write ────────────────────────────────────────────────────────

  Future<int> insertRecord(ExpenseRecordsCompanion record) {
    return into(expenseRecords).insert(record);
  }

  Future<bool> updateRecord(int localId, ExpenseRecordsCompanion record) {
    return (update(expenseRecords)..where((e) => e.localId.equals(localId)))
        .write(
          record.copyWith(
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<bool> softDelete(int localId) {
    return (update(expenseRecords)..where((e) => e.localId.equals(localId)))
        .write(
          ExpenseRecordsCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ── Sync Helpers ─────────────────────────────────────────────────

  Future<List<ExpenseRecord>> getDirtyRecords() {
    return (select(expenseRecords)..where((e) => e.isDirty.equals(true))).get();
  }

  Future<void> markSynced(int localId, String remoteId) {
    return (update(
      expenseRecords,
    )..where((e) => e.localId.equals(localId))).write(
      ExpenseRecordsCompanion(
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> upsertFromRemote(ExpenseRecordsCompanion record) async {
    final remoteId = record.remoteId.value;
    if (remoteId == null) return;

    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        expenseRecords,
      )..where((e) => e.localId.equals(existing.localId))).write(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(expenseRecords).insert(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<int> purgeDeletedAndSynced() {
    return (delete(
      expenseRecords,
    )..where((e) => e.isDeleted.equals(true) & e.isDirty.equals(false))).go();
  }

  Future<int> deleteMissingRemoteIds(Set<String> validRemoteIds) {
    if (validRemoteIds.isEmpty) {
      return (delete(
        expenseRecords,
      )..where((e) => e.remoteId.isNotNull())).go();
    }
    return (delete(expenseRecords)..where(
          (e) => e.remoteId.isNotNull() & e.remoteId.isNotIn(validRemoteIds),
        ))
        .go();
  }
}
