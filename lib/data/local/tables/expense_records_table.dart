import 'package:drift/drift.dart';

/// Local SQLite table for expense records (scanned receipts).
///
/// Mirrors the Supabase `expense_records` table with sync metadata.
class ExpenseRecords extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Remote References ─────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase UUID
  TextColumn get userId => text().nullable()(); // auth.users UUID
  TextColumn get farmId => text().nullable()(); // farm_profiles UUID

  // ── Core Fields ───────────────────────────────────────────────
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get description => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get pricePerUnit => real().nullable()();
  RealColumn get totalValue => real().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
