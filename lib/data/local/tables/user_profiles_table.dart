import 'package:drift/drift.dart';

/// Local SQLite table for cached user profiles.
///
/// Mirrors the Supabase `profiles` table with sync metadata.
class UserProfiles extends Table {
  // ── Primary Key ───────────────────────────────────────────────
  IntColumn get localId => integer().autoIncrement()();

  // ── Core Fields ───────────────────────────────────────────────
  TextColumn get remoteId => text().nullable()(); // Supabase auth.users UUID
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get preferredLanguage =>
      text().withDefault(const Constant('fil'))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();

  // ── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
