import 'package:drift/drift.dart';

/// Local SQLite table for harvest records (scanned crops/produce).
///
/// Mirrors the Supabase `harvest_records` table with sync metadata.
class HarvestRecords extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Remote References ─────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get userId => text().nullable()(); // auth.users UUID
  TextColumn get farmId => text().nullable()(); // farm_profiles UUID

  // ── Core Fields ───────────────────────────────────────────────
  DateTimeColumn get harvestDate => dateTime()();
  TextColumn get cropName => text()();
  RealColumn get totalVolumeKg => real().nullable()();
  RealColumn get institutionalVolumeKg => real().nullable()();
  RealColumn get institutionalPricePhp => real().nullable()();
  RealColumn get otherVolumeKg => real().nullable()();
  RealColumn get otherPricePhp => real().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
