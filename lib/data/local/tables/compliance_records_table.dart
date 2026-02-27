import 'package:drift/drift.dart';

/// Local SQLite table for PhilGAP compliance records.
///
/// Mirrors the Supabase `compliance_records` table with sync metadata.
class ComplianceRecords extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Remote References ─────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get userId => text().nullable()(); // auth.users UUID
  TextColumn get farmId => text().nullable()(); // farm_profiles UUID

  // ── Core Fields ───────────────────────────────────────────────
  TextColumn get formType => text()();
  TextColumn get status => text().withDefault(const Constant('incomplete'))();
  TextColumn get data =>
      text().withDefault(const Constant('{}'))(); // JSON string
  TextColumn get filePath => text().nullable()();
  DateTimeColumn get submittedAt => dateTime().nullable()();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
