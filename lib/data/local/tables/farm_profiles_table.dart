import 'package:drift/drift.dart';

/// Local SQLite table for farm profiles.
///
/// Mirrors the Supabase `farm_profiles` table with sync metadata.
class FarmProfiles extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Remote References ─────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get userId => text().nullable()(); // auth.users UUID

  // ── Core Fields ───────────────────────────────────────────────
  TextColumn get farmerName => text()();
  TextColumn get farmName => text()();
  TextColumn get location => text().nullable()();
  TextColumn get cropType => text().nullable()();
  RealColumn get farmSizeHectares => real().nullable()();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
