// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpenseDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpenseRecordsTable get expenseRecords => attachedDatabase.expenseRecords;
  ExpenseDaoManager get managers => ExpenseDaoManager(this);
}

class ExpenseDaoManager {
  final _$ExpenseDaoMixin _db;
  ExpenseDaoManager(this._db);
  $$ExpenseRecordsTableTableManager get expenseRecords =>
      $$ExpenseRecordsTableTableManager(
        _db.attachedDatabase,
        _db.expenseRecords,
      );
}
