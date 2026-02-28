import 'dart:async';
import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/core/services/connectivity_service.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/daos/farm_dao.dart';
import 'package:sakasama/data/local/daos/activity_dao.dart';
import 'package:sakasama/data/local/daos/compliance_dao.dart';
import 'package:sakasama/data/local/daos/expense_dao.dart';
import 'package:sakasama/data/local/daos/harvest_dao.dart';
import 'package:sakasama/data/local/daos/product_dao.dart';

/// Sync engine: pushes dirty local records to Supabase and pulls remote changes.
///
/// Strategy:
/// - Local SQLite (Drift) is always the source of truth for reads
/// - On write, records are marked `is_dirty = true`
/// - Push: dirty records → Supabase upsert
/// - Pull: full pull from Supabase → local upsert (avoids clock-skew issues)
/// - Realtime: Supabase channels push INSERT/UPDATE/DELETE events live
/// - Periodic: background timer re-syncs every 30 seconds as a fallback
/// - Conflict resolution: last-write-wins (based on `updated_at`)
/// - Soft-delete: mark `is_deleted = true`, sync, then purge
class SyncService {
  SyncService({
    required this.supabase,
    required this.farmDao,
    required this.activityDao,
    required this.complianceDao,
    required this.expenseDao,
    required this.harvestDao,
    required this.productDao,
    required this.connectivity,
  }) {
    // Auto-sync when connectivity is restored
    _connectivitySub = connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncAll();
        _startPeriodicSync();
        _subscribeRealtime();
      } else {
        _stopPeriodicSync();
        _unsubscribeRealtime();
      }
    });
  }

  final SupabaseClient supabase;
  final FarmDao farmDao;
  final ActivityDao activityDao;
  final ComplianceDao complianceDao;
  final ExpenseDao expenseDao;
  final HarvestDao harvestDao;
  final ProductDao productDao;
  final ConnectivityService connectivity;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodicTimer;
  RealtimeChannel? _realtimeChannel;
  bool _isSyncing = false;
  bool _realtimeActive = false;

  static const Duration _syncInterval = Duration(seconds: 30);

  // ── Public API ────────────────────────────────────────────────────

  /// Full sync: push dirty records then pull remote changes.
  /// Also starts periodic sync + realtime if not already running.
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

    // Ensure periodic + realtime are running
    _startPeriodicSync();
    _subscribeRealtime();
  }

  // ── Periodic Sync ────────────────────────────────────────────────

  void _startPeriodicSync() {
    if (_periodicTimer?.isActive ?? false) return;
    _periodicTimer = Timer.periodic(_syncInterval, (_) => syncAll());
    dev.log(
      '[SyncService] Periodic sync started (every ${_syncInterval.inSeconds}s)',
    );
  }

  void _stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // ── Supabase Realtime ────────────────────────────────────────────

  void _subscribeRealtime() {
    if (_realtimeActive) return;
    if (supabase.auth.currentUser == null) return;

    try {
      _realtimeChannel = supabase.channel('db-changes');

      _realtimeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'activity_logs',
            callback: (payload) =>
                _handleRealtimeEvent('activity_logs', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'farm_profiles',
            callback: (payload) =>
                _handleRealtimeEvent('farm_profiles', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'compliance_records',
            callback: (payload) =>
                _handleRealtimeEvent('compliance_records', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'expense_records',
            callback: (payload) =>
                _handleRealtimeEvent('expense_records', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'harvest_records',
            callback: (payload) =>
                _handleRealtimeEvent('harvest_records', payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'product_records',
            callback: (payload) =>
                _handleRealtimeEvent('product_records', payload),
          )
          .subscribe((status, [error]) {
            dev.log('[SyncService] Realtime status: $status');
            if (status == RealtimeSubscribeStatus.subscribed) {
              _realtimeActive = true;
              dev.log('[SyncService] Realtime subscribed to all tables.');
            }
          });
    } catch (e) {
      dev.log('[SyncService] Failed to subscribe realtime: $e');
    }
  }

  void _unsubscribeRealtime() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      _realtimeActive = false;
      dev.log('[SyncService] Realtime unsubscribed.');
    }
  }

  Future<void> _handleRealtimeEvent(
    String table,
    PostgresChangePayload payload,
  ) async {
    dev.log('[SyncService] Realtime $table ${payload.eventType}');

    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final newRecord = payload.newRecord;
          if (newRecord.isEmpty) break;
          await _upsertRemoteRecord(table, newRecord);
          break;

        case PostgresChangeEvent.delete:
          final oldRecord = payload.oldRecord;
          if (oldRecord.isEmpty) break;
          final remoteId = oldRecord['id']?.toString();
          if (remoteId != null) {
            await _deleteLocalByRemoteId(table, remoteId);
          }
          break;

        default:
          syncAll();
      }
    } catch (e) {
      dev.log('[SyncService] Realtime handler error for $table: $e');
      syncAll();
    }
  }

  Future<void> _upsertRemoteRecord(
    String table,
    Map<String, dynamic> remote,
  ) async {
    switch (table) {
      case 'farm_profiles':
        await farmDao.upsertFromRemote(
          FarmProfilesCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmerName: Value(remote['farmer_name'] as String),
            farmName: Value(remote['farm_name'] as String),
            location: Value(remote['location'] as String?),
            cropType: Value(remote['crop_type'] as String?),
            farmSizeHectares: Value(
              (remote['farm_size_hectares'] as num?)?.toDouble(),
            ),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(
              remote['updated_at'] != null
                  ? DateTime.parse(remote['updated_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
        break;

      case 'activity_logs':
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
            updatedAt: Value(
              remote['updated_at'] != null
                  ? DateTime.parse(remote['updated_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
        break;

      case 'compliance_records':
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
            updatedAt: Value(
              remote['updated_at'] != null
                  ? DateTime.parse(remote['updated_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
        break;

      case 'expense_records':
        await expenseDao.upsertFromRemote(
          ExpenseRecordsCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmId: Value(remote['farm_id'] as String?),
            expenseDate: Value(
              DateTime.parse(remote['expense_date'] as String),
            ),
            description: Value(remote['description'] as String? ?? ''),
            quantity: Value((remote['quantity'] as num?)?.toDouble()),
            unit: Value(remote['unit'] as String?),
            pricePerUnit: Value((remote['price_per_unit'] as num?)?.toDouble()),
            totalValue: Value((remote['total_value'] as num?)?.toDouble()),
            photoPath: Value(remote['photo_path'] as String?),
            notes: Value(remote['notes'] as String?),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(
              remote['updated_at'] != null
                  ? DateTime.parse(remote['updated_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
        break;

      case 'harvest_records':
        await harvestDao.upsertFromRemote(
          HarvestRecordsCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmId: Value(remote['farm_id'] as String?),
            harvestDate: Value(
              DateTime.parse(remote['harvest_date'] as String),
            ),
            cropName: Value(remote['crop_name'] as String? ?? ''),
            totalVolumeKg: Value(
              (remote['total_volume_kg'] as num?)?.toDouble(),
            ),
            institutionalVolumeKg: Value(
              (remote['institutional_volume_kg'] as num?)?.toDouble(),
            ),
            institutionalPricePhp: Value(
              (remote['institutional_price_php'] as num?)?.toDouble(),
            ),
            otherVolumeKg: Value(
              (remote['other_volume_kg'] as num?)?.toDouble(),
            ),
            otherPricePhp: Value(
              (remote['other_price_php'] as num?)?.toDouble(),
            ),
            photoPath: Value(remote['photo_path'] as String?),
            notes: Value(remote['notes'] as String?),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(
              remote['updated_at'] != null
                  ? DateTime.parse(remote['updated_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
        break;

      case 'product_records':
        await productDao.upsertFromRemote(
          ProductRecordsCompanion(
            remoteId: Value(remote['id'] as String),
            userId: Value(remote['user_id'] as String?),
            farmId: Value(remote['farm_id'] as String?),
            productName: Value(remote['product_name'] as String? ?? ''),
            productDescription: Value(remote['product_description'] as String?),
            manufacturer: Value(remote['manufacturer'] as String?),
            netWeight: Value(remote['net_weight'] as String?),
            expirationDate: Value(
              remote['expiration_date'] != null
                  ? DateTime.parse(remote['expiration_date'] as String)
                  : null,
            ),
            category: Value(remote['category'] as String?),
            photoPath: Value(remote['photo_path'] as String?),
            notes: Value(remote['notes'] as String?),
            isDeleted: Value(remote['is_deleted'] as bool? ?? false),
            updatedAt: Value(
              remote['updated_at'] != null
                  ? DateTime.parse(remote['updated_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
        break;
    }
  }

  Future<void> _deleteLocalByRemoteId(String table, String remoteId) async {
    switch (table) {
      case 'farm_profiles':
        await farmDao.deleteMissingRemoteIds(
          (await supabase.from('farm_profiles').select('id'))
              .map((r) => r['id'].toString())
              .toSet(),
        );
        break;
      case 'activity_logs':
        await activityDao.deleteMissingRemoteIds(
          (await supabase.from('activity_logs').select('id'))
              .map((r) => r['id'].toString())
              .toSet(),
        );
        break;
      case 'compliance_records':
        await complianceDao.deleteMissingRemoteIds(
          (await supabase.from('compliance_records').select('id'))
              .map((r) => r['id'].toString())
              .toSet(),
        );
        break;
      case 'expense_records':
        await expenseDao.deleteMissingRemoteIds(
          (await supabase.from('expense_records').select('id'))
              .map((r) => r['id'].toString())
              .toSet(),
        );
        break;
      case 'harvest_records':
        await harvestDao.deleteMissingRemoteIds(
          (await supabase.from('harvest_records').select('id'))
              .map((r) => r['id'].toString())
              .toSet(),
        );
        break;
      case 'product_records':
        await productDao.deleteMissingRemoteIds(
          (await supabase.from('product_records').select('id'))
              .map((r) => r['id'].toString())
              .toSet(),
        );
        break;
    }
  }

  // ── Push ──────────────────────────────────────────────────────────

  Future<void> _pushAll() async {
    await _pushFarms();
    await _pushActivities();
    await _pushCompliance();
    await _pushExpenses();
    await _pushHarvests();
    await _pushProducts();
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
          await supabase
              .from('farm_profiles')
              .update(data)
              .eq('id', farm.remoteId!);
          await farmDao.markSynced(farm.localId, farm.remoteId!);
        } else {
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

  Future<void> _pushExpenses() async {
    final dirty = await expenseDao.getDirtyRecords();
    for (final record in dirty) {
      try {
        final data = {
          'user_id': supabase.auth.currentUser!.id,
          'farm_id': record.farmId,
          'expense_date': record.expenseDate.toIso8601String().split('T')[0],
          'description': record.description,
          'quantity': record.quantity,
          'unit': record.unit,
          'price_per_unit': record.pricePerUnit,
          'total_value': record.totalValue,
          'photo_path': record.photoPath,
          'notes': record.notes,
          'is_deleted': record.isDeleted,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (record.remoteId != null) {
          await supabase
              .from('expense_records')
              .update(data)
              .eq('id', record.remoteId!);
          await expenseDao.markSynced(record.localId, record.remoteId!);
        } else {
          final response = await supabase
              .from('expense_records')
              .insert(data)
              .select('id')
              .single();
          await expenseDao.markSynced(record.localId, response['id'] as String);
        }
      } catch (e) {
        dev.log('[SyncService] Push expense ${record.localId} failed: $e');
      }
    }
  }

  Future<void> _pushHarvests() async {
    final dirty = await harvestDao.getDirtyRecords();
    for (final record in dirty) {
      try {
        final data = {
          'user_id': supabase.auth.currentUser!.id,
          'farm_id': record.farmId,
          'harvest_date': record.harvestDate.toIso8601String().split('T')[0],
          'crop_name': record.cropName,
          'total_volume_kg': record.totalVolumeKg,
          'institutional_volume_kg': record.institutionalVolumeKg,
          'institutional_price_php': record.institutionalPricePhp,
          'other_volume_kg': record.otherVolumeKg,
          'other_price_php': record.otherPricePhp,
          'photo_path': record.photoPath,
          'notes': record.notes,
          'is_deleted': record.isDeleted,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (record.remoteId != null) {
          await supabase
              .from('harvest_records')
              .update(data)
              .eq('id', record.remoteId!);
          await harvestDao.markSynced(record.localId, record.remoteId!);
        } else {
          final response = await supabase
              .from('harvest_records')
              .insert(data)
              .select('id')
              .single();
          await harvestDao.markSynced(record.localId, response['id'] as String);
        }
      } catch (e) {
        dev.log('[SyncService] Push harvest ${record.localId} failed: $e');
      }
    }
  }

  Future<void> _pushProducts() async {
    final dirty = await productDao.getDirtyRecords();
    for (final record in dirty) {
      try {
        final data = {
          'user_id': supabase.auth.currentUser!.id,
          'farm_id': record.farmId,
          'product_name': record.productName,
          'product_description': record.productDescription,
          'manufacturer': record.manufacturer,
          'net_weight': record.netWeight,
          'expiration_date': record.expirationDate?.toIso8601String().split(
            'T',
          )[0],
          'category': record.category,
          'photo_path': record.photoPath,
          'notes': record.notes,
          'is_deleted': record.isDeleted,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (record.remoteId != null) {
          await supabase
              .from('product_records')
              .update(data)
              .eq('id', record.remoteId!);
          await productDao.markSynced(record.localId, record.remoteId!);
        } else {
          final response = await supabase
              .from('product_records')
              .insert(data)
              .select('id')
              .single();
          await productDao.markSynced(record.localId, response['id'] as String);
        }
      } catch (e) {
        dev.log('[SyncService] Push product ${record.localId} failed: $e');
      }
    }
  }

  // ── Pull ──────────────────────────────────────────────────────────

  Future<void> _pullAll() async {
    await _pullFarms();
    await _pullActivities();
    await _pullCompliance();
    await _pullExpenses();
    await _pullHarvests();
    await _pullProducts();
  }

  Future<void> _pullFarms() async {
    try {
      final allRemote = await supabase.from('farm_profiles').select();
      final remoteIds = allRemote.map((r) => r['id'].toString()).toSet();
      await farmDao.deleteMissingRemoteIds(remoteIds);

      for (final remote in allRemote) {
        try {
          await farmDao.upsertFromRemote(
            FarmProfilesCompanion(
              remoteId: Value(remote['id'] as String),
              userId: Value(remote['user_id'] as String?),
              farmerName: Value(remote['farmer_name'] as String),
              farmName: Value(remote['farm_name'] as String),
              location: Value(remote['location'] as String?),
              cropType: Value(remote['crop_type'] as String?),
              farmSizeHectares: Value(
                (remote['farm_size_hectares'] as num?)?.toDouble(),
              ),
              isDeleted: Value(remote['is_deleted'] as bool? ?? false),
              updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
            ),
          );
        } catch (e) {
          dev.log('[SyncService] Pull farm record failed: $e');
        }
      }
    } catch (e) {
      dev.log('[SyncService] Pull farms failed: $e');
    }
  }

  Future<void> _pullActivities() async {
    try {
      final allRemote = await supabase.from('activity_logs').select();
      final remoteIds = allRemote.map((r) => r['id'].toString()).toSet();
      await activityDao.deleteMissingRemoteIds(remoteIds);

      for (final remote in allRemote) {
        try {
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
        } catch (e) {
          dev.log('[SyncService] Pull activity record failed: $e');
        }
      }
    } catch (e) {
      dev.log('[SyncService] Pull activities failed: $e');
    }
  }

  Future<void> _pullCompliance() async {
    try {
      final allRemote = await supabase.from('compliance_records').select();
      final remoteIds = allRemote.map((r) => r['id'].toString()).toSet();
      await complianceDao.deleteMissingRemoteIds(remoteIds);

      for (final remote in allRemote) {
        try {
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
        } catch (e) {
          dev.log('[SyncService] Pull compliance record failed: $e');
        }
      }
    } catch (e) {
      dev.log('[SyncService] Pull compliance failed: $e');
    }
  }

  Future<void> _pullExpenses() async {
    try {
      final allRemote = await supabase.from('expense_records').select();
      final remoteIds = allRemote.map((r) => r['id'].toString()).toSet();
      await expenseDao.deleteMissingRemoteIds(remoteIds);

      for (final remote in allRemote) {
        try {
          await expenseDao.upsertFromRemote(
            ExpenseRecordsCompanion(
              remoteId: Value(remote['id'] as String),
              userId: Value(remote['user_id'] as String?),
              farmId: Value(remote['farm_id'] as String?),
              expenseDate: Value(
                DateTime.parse(remote['expense_date'] as String),
              ),
              description: Value(remote['description'] as String? ?? ''),
              quantity: Value((remote['quantity'] as num?)?.toDouble()),
              unit: Value(remote['unit'] as String?),
              pricePerUnit: Value(
                (remote['price_per_unit'] as num?)?.toDouble(),
              ),
              totalValue: Value((remote['total_value'] as num?)?.toDouble()),
              photoPath: Value(remote['photo_path'] as String?),
              notes: Value(remote['notes'] as String?),
              isDeleted: Value(remote['is_deleted'] as bool? ?? false),
              updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
            ),
          );
        } catch (e) {
          dev.log('[SyncService] Pull expense record failed: $e');
        }
      }
    } catch (e) {
      dev.log('[SyncService] Pull expenses failed: $e');
    }
  }

  Future<void> _pullHarvests() async {
    try {
      final allRemote = await supabase.from('harvest_records').select();
      final remoteIds = allRemote.map((r) => r['id'].toString()).toSet();
      await harvestDao.deleteMissingRemoteIds(remoteIds);

      for (final remote in allRemote) {
        try {
          await harvestDao.upsertFromRemote(
            HarvestRecordsCompanion(
              remoteId: Value(remote['id'] as String),
              userId: Value(remote['user_id'] as String?),
              farmId: Value(remote['farm_id'] as String?),
              harvestDate: Value(
                DateTime.parse(remote['harvest_date'] as String),
              ),
              cropName: Value(remote['crop_name'] as String? ?? ''),
              totalVolumeKg: Value(
                (remote['total_volume_kg'] as num?)?.toDouble(),
              ),
              institutionalVolumeKg: Value(
                (remote['institutional_volume_kg'] as num?)?.toDouble(),
              ),
              institutionalPricePhp: Value(
                (remote['institutional_price_php'] as num?)?.toDouble(),
              ),
              otherVolumeKg: Value(
                (remote['other_volume_kg'] as num?)?.toDouble(),
              ),
              otherPricePhp: Value(
                (remote['other_price_php'] as num?)?.toDouble(),
              ),
              photoPath: Value(remote['photo_path'] as String?),
              notes: Value(remote['notes'] as String?),
              isDeleted: Value(remote['is_deleted'] as bool? ?? false),
              updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
            ),
          );
        } catch (e) {
          dev.log('[SyncService] Pull harvest record failed: $e');
        }
      }
    } catch (e) {
      dev.log('[SyncService] Pull harvests failed: $e');
    }
  }

  Future<void> _pullProducts() async {
    try {
      final allRemote = await supabase.from('product_records').select();
      final remoteIds = allRemote.map((r) => r['id'].toString()).toSet();
      await productDao.deleteMissingRemoteIds(remoteIds);

      for (final remote in allRemote) {
        try {
          await productDao.upsertFromRemote(
            ProductRecordsCompanion(
              remoteId: Value(remote['id'] as String),
              userId: Value(remote['user_id'] as String?),
              farmId: Value(remote['farm_id'] as String?),
              productName: Value(remote['product_name'] as String? ?? ''),
              productDescription: Value(
                remote['product_description'] as String?,
              ),
              manufacturer: Value(remote['manufacturer'] as String?),
              netWeight: Value(remote['net_weight'] as String?),
              expirationDate: Value(
                remote['expiration_date'] != null
                    ? DateTime.parse(remote['expiration_date'] as String)
                    : null,
              ),
              category: Value(remote['category'] as String?),
              photoPath: Value(remote['photo_path'] as String?),
              notes: Value(remote['notes'] as String?),
              isDeleted: Value(remote['is_deleted'] as bool? ?? false),
              updatedAt: Value(DateTime.parse(remote['updated_at'] as String)),
            ),
          );
        } catch (e) {
          dev.log('[SyncService] Pull product record failed: $e');
        }
      }
    } catch (e) {
      dev.log('[SyncService] Pull products failed: $e');
    }
  }

  // ── Purge ─────────────────────────────────────────────────────────

  Future<void> _purgeAll() async {
    await farmDao.purgeDeletedAndSynced();
    await activityDao.purgeDeletedAndSynced();
    await complianceDao.purgeDeletedAndSynced();
    await expenseDao.purgeDeletedAndSynced();
    await harvestDao.purgeDeletedAndSynced();
    await productDao.purgeDeletedAndSynced();
  }

  /// Dispose subscriptions and timers.
  void dispose() {
    _connectivitySub?.cancel();
    _stopPeriodicSync();
    _unsubscribeRealtime();
  }
}
