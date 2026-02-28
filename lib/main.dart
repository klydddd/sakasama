import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sakasama/app.dart';
import 'package:sakasama/core/config/supabase_config.dart';
import 'package:sakasama/core/routing/app_router.dart';

/// Entry point for the Sakasama app.
///
/// Initializes Supabase, loads env, checks onboarding state, then runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent google_fonts from trying to download fonts at runtime
  // (crashes when device has no internet / DNS resolution fails)
  GoogleFonts.config.allowRuntimeFetching = false;

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize SharedPreferences for AppRouter
  final prefs = await SharedPreferences.getInstance();
  AppRouter.prefs = prefs;

  runApp(const ProviderScope(child: SakasamaApp()));
}
