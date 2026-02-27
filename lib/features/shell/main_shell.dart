import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';

/// Main navigation shell with bottom navigation bar.
///
/// Contains 4 tabs: Home, Journal, Saka (Voice), Export.
/// Uses [ShellRoute] from go_router for nested navigation.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  /// Maps route paths to bottom nav indices.
  static int _locationToIndex(String location) {
    if (location.startsWith('/journal')) return 1;
    if (location.startsWith('/voice')) return 2;
    if (location.startsWith('/export')) return 3;
    return 0;
  }

  /// Maps bottom nav indices back to route paths.
  static const List<String> _indexToPath = [
    '/',
    '/journal',
    '/voice',
    '/export',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(
      GoRouterState.of(context).uri.toString(),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index != currentIndex) {
                  context.go(_indexToPath[index]);
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded),
                  label: AppStrings.navHome,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  activeIcon: Icon(Icons.menu_book_rounded),
                  label: AppStrings.navJournal,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mic_rounded),
                  activeIcon: Icon(Icons.mic_rounded),
                  label: AppStrings.navSaka,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.file_download_outlined),
                  activeIcon: Icon(Icons.file_download_rounded),
                  label: AppStrings.navExport,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
