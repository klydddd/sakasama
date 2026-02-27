import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Stream provider watching all activity logs from local DB (newest first).
final allActivitiesProvider = StreamProvider<List<ActivityLog>>((ref) {
  final activityDao = ref.watch(activityDaoProvider);
  return activityDao.watchAll();
});

/// Future provider returning the total count of activity logs.
final activityCountProvider = FutureProvider<int>((ref) {
  final activityDao = ref.watch(activityDaoProvider);
  return activityDao.countActivities();
});

/// Stream provider counting distinct dates that have activity entries.
/// Used by the dashboard progress card ("days logged").
final daysLoggedProvider = StreamProvider<int>((ref) {
  final activityDao = ref.watch(activityDaoProvider);
  return activityDao.watchAll().map((activities) {
    // Count unique dates
    final uniqueDates = <String>{};
    for (final a in activities) {
      uniqueDates.add(
        '${a.activityDate.year}-${a.activityDate.month}-${a.activityDate.day}',
      );
    }
    return uniqueDates.length;
  });
});
