import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/features/auth/screens/login_screen.dart';
import 'package:sakasama/features/auth/screens/register_screen.dart';
import 'package:sakasama/features/audit_export/screens/export_screen.dart';
import 'package:sakasama/features/compliance_forms/screens/form_detail_screen.dart';
import 'package:sakasama/features/compliance_forms/screens/forms_list_screen.dart';
import 'package:sakasama/features/dashboard/screens/dashboard_screen.dart';
import 'package:sakasama/features/farm_journal/screens/activity_form_screen.dart';
import 'package:sakasama/features/farm_journal/screens/journal_list_screen.dart';
import 'package:sakasama/features/ocr_scan/screens/camera_scan_screen.dart';
import 'package:sakasama/features/ocr_scan/screens/ocr_review_screen.dart';
import 'package:sakasama/features/records/screens/expense_list_screen.dart';
import 'package:sakasama/features/records/screens/harvest_list_screen.dart';
import 'package:sakasama/features/records/screens/product_list_screen.dart';
import 'package:sakasama/features/onboarding/screens/farm_setup_screen.dart';
import 'package:sakasama/features/onboarding/screens/language_selection_screen.dart';
import 'package:sakasama/features/onboarding/screens/permissions_screen.dart';
import 'package:sakasama/features/onboarding/screens/welcome_screen.dart';
import 'package:sakasama/features/settings/screens/settings_screen.dart';
import 'package:sakasama/features/shell/main_shell.dart';
import 'package:sakasama/features/voice_assistant/screens/voice_assistant_screen.dart';
import 'package:sakasama/features/voice_assistant/screens/conversation_screen.dart';

/// App-wide routing configuration using go_router.
///
/// Routes:
/// - /login, /register — Auth flow
/// - /onboarding/* — First-launch linear flow
/// - / — Main shell with bottom navigation
/// - /scan — OCR camera scan
/// - /compliance — Compliance forms list
/// - /settings — Settings screen
class AppRouter {
  AppRouter._();

  /// SharedPreferences instance injected from main.dart
  static late SharedPreferences prefs;

  /// Checks if the specific user has completed onboarding.
  static bool isOnboardingCompleted(String userId) {
    if (userId.isEmpty) return false;
    final userSpecific = prefs.getBool('onboarding_completed_$userId');
    if (userSpecific != null) return userSpecific;

    // Fallback for existing users
    final globalCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (globalCompleted) {
      prefs.setBool('onboarding_completed_$userId', true);
      return true;
    }
    return false;
  }

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');

      // Not logged in → force to login (unless already there)
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Logged in user routing
      final hasCompletedOnboarding = isOnboardingCompleted(userId ?? '');

      if (!hasCompletedOnboarding) {
        // Must complete onboarding
        if (!isOnboardingRoute) {
          return '/onboarding';
        }
      } else {
        // Has completed onboarding
        if (isAuthRoute || isOnboardingRoute) {
          return '/';
        }
      }

      return null; // no redirect
    },
    routes: [
      // ── Auth Routes ─────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Onboarding Flow ─────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/farm-setup',
        builder: (context, state) => const FarmSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),

      // ── Main Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
        ],
      ),

      // ── Top-Level Screens ───────────────────────────────────────────
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalListScreen(),
      ),
      GoRoute(
        path: '/voice',
        builder: (context, state) => const VoiceAssistantScreen(),
      ),
      GoRoute(
        path: '/conversation',
        builder: (context, state) => const ConversationScreen(),
      ),
      GoRoute(
        path: '/export',
        builder: (context, state) => const ExportScreen(),
      ),

      // ── Standalone Routes ───────────────────────────────────────────
      GoRoute(
        path: '/scan',
        builder: (context, state) => const CameraScanScreen(),
      ),
      GoRoute(
        path: '/scan/review',
        builder: (context, state) {
          final imagePath = state.extra as String? ?? '';
          return OcrReviewScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/journal/add',
        builder: (context, state) => const ActivityFormScreen(),
      ),
      GoRoute(
        path: '/compliance',
        builder: (context, state) => const FormsListScreen(),
      ),
      GoRoute(
        path: '/compliance/detail',
        builder: (context, state) {
          final formType = state.uri.queryParameters['formType'] ?? '';
          return FormDetailScreen(formType: formType);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Record List Screens ──────────────────────────────────────
      GoRoute(
        path: '/records/expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: '/records/harvests',
        builder: (context, state) => const HarvestListScreen(),
      ),
      GoRoute(
        path: '/records/products',
        builder: (context, state) => const ProductListScreen(),
      ),
    ],
  );
}
