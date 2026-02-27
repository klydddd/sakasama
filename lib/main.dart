import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/app.dart';
import 'package:sakasama/core/config/supabase_config.dart';

/// Entry point for the Sakasama app.
///
/// Initializes Supabase, then runs the app wrapped in [ProviderScope].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: SakasamaApp()));
}
