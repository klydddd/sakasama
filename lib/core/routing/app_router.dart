import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:sakasama/features/onboarding/screens/farm_setup_screen.dart';
import 'package:sakasama/features/onboarding/screens/language_selection_screen.dart';
import 'package:sakasama/features/onboarding/screens/permissions_screen.dart';
import 'package:sakasama/features/onboarding/screens/welcome_screen.dart';
import 'package:sakasama/features/settings/screens/settings_screen.dart';
import 'package:sakasama/features/shell/main_shell.dart';
import 'package:sakasama/features/voice_assistant/screens/voice_assistant_screen.dart';

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

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Not logged in → force to login (unless already there)
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Logged in but on auth route → go to onboarding or home
      if (isLoggedIn && isAuthRoute) {
        return '/onboarding';
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

      // ── Main Shell (Bottom Nav) ─────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: JournalListScreen()),
          ),
          GoRoute(
            path: '/voice',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VoiceAssistantScreen()),
          ),
          GoRoute(
            path: '/export',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ExportScreen()),
          ),
        ],
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
        builder: (context, state) => const FormDetailScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
