import 'package:drift/drift.dart';
import 'package:sakasama/data/local/daos/farm_dao.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/core/services/sync_service.dart';

/// Repository for farm profile data.
///
/// Reads always come from the local SQLite database.
/// Writes go to local DB first (marked dirty), then trigger sync.
class FarmRepository {
  FarmRepository({required this.farmDao, required this.syncService});

  final FarmDao farmDao;
  final SyncService syncService;

  /// Watch all farms (reactive stream from local DB).
  Stream<List<FarmProfile>> watchAll(String userId) => farmDao.watchAll(userId);

  /// Get all farms (one-shot from local DB).
  Future<List<FarmProfile>> getAll(String userId) => farmDao.getAll(userId);

  /// Get a farm by local ID.
  Future<FarmProfile?> getById(int localId) => farmDao.getById(localId);

  /// Create a new farm profile.
  Future<int> create({
    required String farmerName,
    required String farmName,
    String? location,
    String? cropType,
    double? farmSize,
    String? userId,
  }) async {
    final id = await farmDao.insertFarm(
      FarmProfilesCompanion.insert(
        farmerName: farmerName,
        farmName: farmName,
        location: Value(location),
        cropType: Value(cropType),
        farmSizeHectares: Value(farmSize),
        userId: Value(userId),
      ),
    );

    // Trigger background sync
    syncService.syncAll();

    return id;
  }

  /// Update an existing farm profile.
  Future<bool> update(
    int localId, {
    String? farmerName,
    String? farmName,
    String? location,
    String? cropType,
    double? farmSize,
  }) async {
    final result = await farmDao.updateFarm(
      localId,
      FarmProfilesCompanion(
        farmerName: farmerName != null
            ? Value(farmerName)
            : const Value.absent(),
        farmName: farmName != null ? Value(farmName) : const Value.absent(),
        location: location != null ? Value(location) : const Value.absent(),
        cropType: cropType != null ? Value(cropType) : const Value.absent(),
        farmSizeHectares: farmSize != null
            ? Value(farmSize)
            : const Value.absent(),
      ),
    );

    syncService.syncAll();
    return result;
  }

  /// Soft-delete a farm.
  Future<void> delete(int localId) async {
    await farmDao.softDelete(localId);
    syncService.syncAll();
  }
}
