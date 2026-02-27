import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  AppRouter.onboardingCompleted = onboardingCompleted;

  runApp(const ProviderScope(child: SakasamaApp()));
}
