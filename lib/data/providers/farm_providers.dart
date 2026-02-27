import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Stream provider watching the first (active) farm profile from local DB.
///
/// Returns null if no farm profile exists yet (e.g. before onboarding).
final activeFarmProfileProvider = StreamProvider<FarmProfile?>((ref) {
  final farmDao = ref.watch(farmDaoProvider);
  return farmDao.watchAll().map(
    (farms) => farms.isNotEmpty ? farms.first : null,
  );
});

/// One-shot provider to get all farm profiles.
final allFarmProfilesProvider = FutureProvider<List<FarmProfile>>((ref) {
  final farmDao = ref.watch(farmDaoProvider);
  return farmDao.getAll();
});
