// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'harvest_dao.dart';

// ignore_for_file: type=lint
mixin _$HarvestDaoMixin on DatabaseAccessor<AppDatabase> {
  $HarvestRecordsTable get harvestRecords => attachedDatabase.harvestRecords;
  HarvestDaoManager get managers => HarvestDaoManager(this);
}

class HarvestDaoManager {
  final _$HarvestDaoMixin _db;
  HarvestDaoManager(this._db);
  $$HarvestRecordsTableTableManager get harvestRecords =>
      $$HarvestRecordsTableTableManager(
        _db.attachedDatabase,
        _db.harvestRecords,
      );
}
