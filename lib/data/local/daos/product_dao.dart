import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/product_records_table.dart';

part 'product_dao.g.dart';

/// Data Access Object for ProductRecords table.
@DriftAccessor(tables: [ProductRecords])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  Stream<List<ProductRecord>> watchAll(String userId) {
    return (select(productRecords)
          ..where((p) => p.isDeleted.equals(false) & p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  Future<List<ProductRecord>> getAll(String userId) {
    return (select(productRecords)
          ..where((p) => p.isDeleted.equals(false) & p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Future<ProductRecord?> getByRemoteId(String remoteId) {
    return (select(
      productRecords,
    )..where((p) => p.remoteId.equals(remoteId))).getSingleOrNull();
  }

  // ── Write ────────────────────────────────────────────────────────

  Future<int> insertRecord(ProductRecordsCompanion record) {
    return into(productRecords).insert(record);
  }

  Future<bool> updateRecord(int localId, ProductRecordsCompanion record) {
    return (update(productRecords)..where((p) => p.localId.equals(localId)))
        .write(
          record.copyWith(
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<bool> softDelete(int localId) {
    return (update(productRecords)..where((p) => p.localId.equals(localId)))
        .write(
          ProductRecordsCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ── Sync Helpers ─────────────────────────────────────────────────

  Future<List<ProductRecord>> getDirtyRecords() {
    return (select(productRecords)..where((p) => p.isDirty.equals(true))).get();
  }

  Future<void> markSynced(int localId, String remoteId) {
    return (update(
      productRecords,
    )..where((p) => p.localId.equals(localId))).write(
      ProductRecordsCompanion(
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> upsertFromRemote(ProductRecordsCompanion record) async {
    final remoteId = record.remoteId.value;
    if (remoteId == null) return;

    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        productRecords,
      )..where((p) => p.localId.equals(existing.localId))).write(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(productRecords).insert(
        record.copyWith(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<int> purgeDeletedAndSynced() {
    return (delete(
      productRecords,
    )..where((p) => p.isDeleted.equals(true) & p.isDirty.equals(false))).go();
  }

  Future<int> deleteMissingRemoteIds(Set<String> validRemoteIds) {
    if (validRemoteIds.isEmpty) {
      return (delete(
        productRecords,
      )..where((p) => p.remoteId.isNotNull())).go();
    }
    return (delete(productRecords)..where(
          (p) => p.remoteId.isNotNull() & p.remoteId.isNotIn(validRemoteIds),
        ))
        .go();
  }
}
