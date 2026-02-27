// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compliance_dao.dart';

// ignore_for_file: type=lint
mixin _$ComplianceDaoMixin on DatabaseAccessor<AppDatabase> {
  $ComplianceRecordsTable get complianceRecords =>
      attachedDatabase.complianceRecords;
  ComplianceDaoManager get managers => ComplianceDaoManager(this);
}

class ComplianceDaoManager {
  final _$ComplianceDaoMixin _db;
  ComplianceDaoManager(this._db);
  $$ComplianceRecordsTableTableManager get complianceRecords =>
      $$ComplianceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.complianceRecords,
      );
}
