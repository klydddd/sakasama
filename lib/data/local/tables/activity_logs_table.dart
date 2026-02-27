import 'package:drift/drift.dart';

/// Local SQLite table for farm activity logs.
///
/// Mirrors the Supabase `activity_logs` table with sync metadata.
class ActivityLogs extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Remote References ─────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get userId => text().nullable()(); // auth.users UUID
  TextColumn get farmId => text().nullable()(); // farm_profiles UUID

  // ── Core Fields ───────────────────────────────────────────────
  DateTimeColumn get activityDate => dateTime()();
  TextColumn get activityType => text()();
  TextColumn get productUsed => text().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
