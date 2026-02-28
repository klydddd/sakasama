import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/data/local/app_database.dart';
import 'package:sakasama/data/providers/database_providers.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Stream provider watching all activity logs from local DB (newest first).
final allActivitiesProvider = StreamProvider<List<ActivityLog>>((ref) {
  final activityDao = ref.watch(activityDaoProvider);
  final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
  return activityDao.watchAll(userId);
});

/// Future provider returning the total count of activity logs.
final activityCountProvider = FutureProvider<int>((ref) {
  final activityDao = ref.watch(activityDaoProvider);
  final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
  return activityDao.countActivities(userId);
});

/// Stream provider counting distinct dates that have activity entries.
/// Used by the dashboard progress card ("days logged").
final daysLoggedProvider = StreamProvider<int>((ref) {
  final activityDao = ref.watch(activityDaoProvider);
  final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
  return activityDao.watchAll(userId).map((activities) {
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
