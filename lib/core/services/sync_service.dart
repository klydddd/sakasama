import 'dart:async';
import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/core/services/connectivity_service.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/daos/farm_dao.dart';
import 'package:sakasama/data/local/daos/activity_dao.dart';
import 'package:sakasama/data/local/daos/compliance_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sync engine: pushes dirty local records to Supabase and pulls remote changes.
///
/// Strategy:
/// - Local SQLite (Drift) is always the source of truth
/// - On write, records are marked `is_dirty = true`
/// - Push: dirty records → Supabase upsert
/// - Pull: Supabase records where `updated_at > last_sync_time` → local upsert
/// - Conflict resolution: last-write-wins (based on `updated_at`)
/// - Soft-delete: mark `is_deleted = true`, sync, then purge
class SyncService {
  SyncService({
    required this.supabase,
    required this.farmDao,
    required this.activityDao,
    required this.complianceDao,
    required this.connectivity,
  }) {
    // Auto-sync when connectivity is restored
    _connectivitySub = connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncAll();
      }
    });
  }

  final SupabaseClient supabase;
  final FarmDao farmDao;
  final ActivityDao activityDao;
  final ComplianceDao complianceDao;
  final ConnectivityService connectivity;

  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  static const String _lastSyncKey = 'last_sync_timestamp';

  // ── Public API ────────────────────────────────────────────────────

  /// Full sync: push dirty records then pull remote changes.
  Future<void> syncAll() async {
    if (_isSyncing || !connectivity.isOnline) return;
    if (supabase.auth.currentUser == null) return;

    _isSyncing = true;
    dev.log('[SyncService] Starting full sync...');

    try {
      await _pushAll();
      await _pullAll();
      await _purgeAll();
      dev.log('[SyncService] Sync complete.');
    } catch (e) {
      dev.log('[SyncService] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Push ──────────────────────────────────────────────────────────

  Future<void> _pushAll() async {
    await _pushFarms();
    await _pushActivities();
    await _pushCompliance();
  }

  Future<void> _pushFarms() async {
    final dirtyFarms = await farmDao.getDirtyRecords();
    for (final farm in dirtyFarms) {
      try {
        final data = {
          'user_id': supabase.auth.currentUser!.id,
          'farmer_name': farm.farmerName,
          'farm_name': farm.farmName,
          'location': farm.location,
          'crop_type': farm.cropType,
          'farm_size_hectares': farm.farmSizeHectares,
          'is_deleted': farm.isDeleted,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (farm.remoteId != null) {
          // Update existing remote record
          await supabase
              .from('farm_profiles')
              .update(data)
              .eq('id', farm.remoteId!);
          await farmDao.markSynced(farm.localId, farm.remoteId!);
        } else {
          // Insert new remote record
          final response = await supabase
              .from('farm_profiles')
              .insert(data)
              .select('id')
              .single();
          await farmDao.markSynced(farm.localId, response['id'] as String);
        }
      } catch (e) {
        dev.log('[SyncService] Push farm ${farm.localId} failed: $e');
      }
    }
  }

  Future<void> _pushActivities() async {
    final dirtyLogs = await activityDao.getDirtyRecords();
    for (final log in dirtyLogs) {
      try {
        final data = {
          'user_id': supabase.auth.currentUser!.id,
          'farm_id': log.farmId,
          'activity_date': log.activityDate.toIso8601String().split('T')[0],
          'activity_type': log.activityType,
          'product_used': log.productUsed,
          'quantity': log.quantity,
          'unit': log.unit,
          'notes': log.notes,
          'photo_path': log.photoPath,
          'is_deleted': log.isDeleted,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (log.remoteId != null) {
          await supabase
              .from('activity_logs')
              .update(data)
              .eq('id', log.remoteId!);
          await activityDao.markSynced(log.localId, log.remoteId!);
        } else {
          final response = await supabase
              .from('activity_logs')
              .insert(data)
              .select('id')
              .single();
          await activityDao.markSynced(log.localId, response['id'] as String);
        }
      } catch (e) {
        dev.log('[SyncService] Push activity ${log.localId} failed: $e');
      }
    }
  }

  Future<void> _pushCompliance() async {
    final dirtyRecords = await complianceDao.getDirtyRecords();
    for (final record in dirtyRecords) {
      try {
        final data = {
          'user_id': supabase.auth.currentUser!.id,
          'farm_id': record.farmId,
          'form_type': record.formType,
          'status': record.status,
          'data': record.data,
          'file_path': record.filePath,
          'submitted_at': record.submittedAt?.toIso8601String(),
          'is_deleted': record.isDeleted,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (record.remoteId != null) {
          await supabase
              .from('compliance_records')
              .update(data)
              .eq('id', record.remoteId!);
          await complianceDao.markSynced(record.localId, record.remoteId!);
        } else {
          final response = await supabase
              .from('compliance_records')
              .insert(data)
              .select('id')
              .single();
          await complianceDao.markSynced(
            record.localId,
            response['id'] as String,
          );
        }
      } catch (e) {
        dev.log('[SyncService] Push compliance ${record.localId} failed: $e');
      }
    }
  }

  // ── Pull ──────────────────────────────────────────────────────────

  Future<void> _pullAll() async {
    final lastSync = await _getLastSyncTime();
    await _pullFarms(lastSync);
    await _pullActivities(lastSync);
    await _pullCompliance(lastSync);
    await _setLastSyncTime(DateTime.now());
  }

  Future<void> _pullFarms(DateTime? lastSync) async {
    try {
      var query = supabase.from('farm_profiles').select();
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }
      final remoteFarms = await query;

      for (final remote in remoteFarms) {
        await farmDao.upsertFromRemote(
          FarmProfilesCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmerName: Value(remote['farmer_name'] as String),
            farmName: Value(remote['farm_name'] as String),
            location: Value(remote['location'] as String?),
            cropType: Value(remote['crop_type'] as String?),
            farmSizeHectares: Value(remote['farm_size_hectares'] as double?),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
          ),
        );
      }
    } catch (e) {
      dev.log('[SyncService] Pull farms failed: $e');
    }
  }

  Future<void> _pullActivities(DateTime? lastSync) async {
    try {
      var query = supabase.from('activity_logs').select();
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }
      final remoteLogs = await query;

      for (final remote in remoteLogs) {
        await activityDao.upsertFromRemote(
          ActivityLogsCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmId: Value(remote['farm_id'] as String?),
            activityDate: Value(
              DateTime.parse(remote['activity_date'] as String),
            ),
            activityType: Value(remote['activity_type'] as String),
            productUsed: Value(remote['product_used'] as String?),
            quantity: Value((remote['quantity'] as num?)?.toDouble()),
            unit: Value(remote['unit'] as String?),
            notes: Value(remote['notes'] as String?),
            photoPath: Value(remote['photo_path'] as String?),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
          ),
        );
      }
    } catch (e) {
      dev.log('[SyncService] Pull activities failed: $e');
    }
  }

  Future<void> _pullCompliance(DateTime? lastSync) async {
    try {
      var query = supabase.from('compliance_records').select();
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }
      final remoteRecords = await query;

      for (final remote in remoteRecords) {
        await complianceDao.upsertFromRemote(
          ComplianceRecordsCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmId: Value(remote['farm_id'] as String?),
            formType: Value(remote['form_type'] as String),
            status: Value(remote['status'] as String),
            data: Value(remote['data']?.toString() ?? '{}'),
            filePath: Value(remote['file_path'] as String?),
            submittedAt: Value(
              remote['submitted_at'] != null
                  ? DateTime.parse(remote['submitted_at'] as String)
                  : null,
            ),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
          ),
        );
      }
    } catch (e) {
      dev.log('[SyncService] Pull compliance failed: $e');
    }
  }

  // ── Purge ─────────────────────────────────────────────────────────

  Future<void> _purgeAll() async {
    await farmDao.purgeDeletedAndSynced();
    await activityDao.purgeDeletedAndSynced();
    await complianceDao.purgeDeletedAndSynced();
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Future<DateTime?> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_lastSyncKey);
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  Future<void> _setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  /// Dispose subscriptions.
  void dispose() {
    _connectivitySub?.cancel();
  }
}
