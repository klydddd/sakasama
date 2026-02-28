// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductRecordsTable get productRecords => attachedDatabase.productRecords;
  ProductDaoManager get managers => ProductDaoManager(this);
}

class ProductDaoManager {
  final _$ProductDaoMixin _db;
  ProductDaoManager(this._db);
  $$ProductRecordsTableTableManager get productRecords =>
      $$ProductRecordsTableTableManager(
        _db.attachedDatabase,
        _db.productRecords,
      );
}
