import 'package:drift/drift.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/local/tables/user_profiles_table.dart';

part 'user_profile_dao.g.dart';

/// Data Access Object for UserProfiles table.
///
/// Provides methods to query and update user profiles, including
/// the onboarding-completed flag used by the router.
@DriftAccessor(tables: [UserProfiles])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────

  /// Get the user profile for a given Supabase remote ID.
  Future<UserProfile?> getByRemoteId(String remoteId) {
    return (select(
      userProfiles,
    )..where((u) => u.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Check whether onboarding has been completed for any user.
  Future<bool> isOnboardingCompleted() async {
    final profile =
        await (select(userProfiles)
              ..where((u) => u.onboardingCompleted.equals(true))
              ..limit(1))
            .getSingleOrNull();
    return profile != null;
  }

  // ── Write ────────────────────────────────────────────────────────

  /// Insert a new user profile.
  Future<int> insertProfile(UserProfilesCompanion profile) {
    return into(userProfiles).insert(profile);
  }

  /// Mark onboarding as completed for a user by remote ID.
  /// If no profile exists yet, creates one.
  Future<void> markOnboardingCompleted(
    String remoteId, {
    String? email,
    String? displayName,
  }) async {
    final existing = await getByRemoteId(remoteId);
    if (existing != null) {
      await (update(
        userProfiles,
      )..where((u) => u.localId.equals(existing.localId))).write(
        UserProfilesCompanion(
          onboardingCompleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(userProfiles).insert(
        UserProfilesCompanion(
          remoteId: Value(remoteId),
          email: Value(email),
          displayName: Value(displayName),
          onboardingCompleted: const Value(true),
        ),
      );
    }
  }
}
