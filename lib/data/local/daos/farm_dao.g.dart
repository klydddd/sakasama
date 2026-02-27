// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm_dao.dart';

// ignore_for_file: type=lint
mixin _$FarmDaoMixin on DatabaseAccessor<AppDatabase> {
  $FarmProfilesTable get farmProfiles => attachedDatabase.farmProfiles;
  FarmDaoManager get managers => FarmDaoManager(this);
}

class FarmDaoManager {
  final _$FarmDaoMixin _db;
  FarmDaoManager(this._db);
  $$FarmProfilesTableTableManager get farmProfiles =>
      $$FarmProfilesTableTableManager(_db.attachedDatabase, _db.farmProfiles);
}
