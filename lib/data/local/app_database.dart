import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sakasama/data/local/tables/user_profiles_table.dart';
import 'package:sakasama/data/local/tables/farm_profiles_table.dart';
import 'package:sakasama/data/local/tables/activity_logs_table.dart';
import 'package:sakasama/data/local/tables/compliance_records_table.dart';
import 'package:sakasama/data/local/tables/expense_records_table.dart';
import 'package:sakasama/data/local/tables/harvest_records_table.dart';
import 'package:sakasama/data/local/tables/product_records_table.dart';
import 'package:sakasama/data/local/daos/user_profile_dao.dart';
import 'package:sakasama/data/local/daos/farm_dao.dart';
import 'package:sakasama/data/local/daos/activity_dao.dart';
import 'package:sakasama/data/local/daos/compliance_dao.dart';
import 'package:sakasama/data/local/daos/expense_dao.dart';
import 'package:sakasama/data/local/daos/harvest_dao.dart';
import 'package:sakasama/data/local/daos/product_dao.dart';

part 'app_database.g.dart';

/// Drift (SQLite) database for Sakasama.
///
/// Contains 7 tables with sync metadata columns.
/// All reads happen from this local DB; writes are marked dirty for sync.
@DriftDatabase(
  tables: [
    UserProfiles,
    FarmProfiles,
    ActivityLogs,
    ComplianceRecords,
    ExpenseRecords,
    HarvestRecords,
    ProductRecords,
  ],
  daos: [
    UserProfileDao,
    FarmDao,
    ActivityDao,
    ComplianceDao,
    ExpenseDao,
    HarvestDao,
    ProductDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Destructive migration: drop all and recreate
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
      }
      await m.createAll();
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'sakasama_db');
  }
}
