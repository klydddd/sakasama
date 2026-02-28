import 'package:drift/drift.dart';

/// Local SQLite table for product records (scanned products).
///
/// Mirrors the Supabase `product_records` table with sync metadata.
class ProductRecords extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Remote References ─────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get userId => text().nullable()(); // auth.users UUID
  TextColumn get farmId => text().nullable()(); // farm_profiles UUID

  // ── Core Fields ───────────────────────────────────────────────
  TextColumn get productName => text()();
  TextColumn get productDescription => text().nullable()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get netWeight => text().nullable()();
  DateTimeColumn get expirationDate => dateTime().nullable()();
  TextColumn get category =>
      text().nullable()(); // fertilizer, pesticide, seed, other
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
