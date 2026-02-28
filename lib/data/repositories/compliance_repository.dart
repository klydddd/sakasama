import 'package:drift/drift.dart';
import 'package:sakasama/data/local/daos/compliance_dao.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/core/services/sync_service.dart';

/// Repository for compliance record data.
///
/// Reads always come from the local SQLite database.
/// Writes go to local DB first (marked dirty), then trigger sync.
class ComplianceRepository {
  ComplianceRepository({
    required this.complianceDao,
    required this.syncService,
  });

  final ComplianceDao complianceDao;
  final SyncService syncService;

  /// Watch all compliance records (reactive stream).
  Stream<List<ComplianceRecord>> watchAll(String userId) =>
      complianceDao.watchAll(userId);

  /// Get all compliance records (one-shot).
  Future<List<ComplianceRecord>> getAll(String userId) =>
      complianceDao.getAll(userId);

  /// Watch records by form type.
  Stream<List<ComplianceRecord>> watchByFormType(
    String formType,
    String userId,
  ) => complianceDao.watchByFormType(formType, userId);

  /// Get a single record by ID.
  Future<ComplianceRecord?> getById(int localId) =>
      complianceDao.getById(localId);

  /// Create a new compliance record.
  Future<int> create({
    required String formType,
    String status = 'incomplete',
    String data = '{}',
    String? filePath,
    String? farmId,
    String? userId,
  }) async {
    final id = await complianceDao.insertRecord(
      ComplianceRecordsCompanion.insert(
        formType: formType,
        status: Value(status),
        data: Value(data),
        filePath: Value(filePath),
        farmId: Value(farmId),
        userId: Value(userId),
      ),
    );

    syncService.syncAll();
    return id;
  }

  /// Update an existing compliance record.
  Future<bool> update(
    int localId, {
    String? status,
    String? data,
    String? filePath,
    DateTime? submittedAt,
  }) async {
    final result = await complianceDao.updateRecord(
      localId,
      ComplianceRecordsCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        data: data != null ? Value(data) : const Value.absent(),
        filePath: filePath != null ? Value(filePath) : const Value.absent(),
        submittedAt: submittedAt != null
            ? Value(submittedAt)
            : const Value.absent(),
      ),
    );

    syncService.syncAll();
    return result;
  }

  /// Soft-delete a compliance record.
  Future<void> delete(int localId) async {
    await complianceDao.softDelete(localId);
    syncService.syncAll();
  }
}
