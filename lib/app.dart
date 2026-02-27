import 'package:flutter/material.dart';
import 'package:sakasama/core/routing/app_router.dart';
import 'package:sakasama/core/theme/app_theme.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Root widget for the Sakasama app.
///
/// Sets up MaterialApp.router with the Sakasama theme and go_router.
class SakasamaApp extends StatelessWidget {
  const SakasamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
