import 'package:flutter/material.dart';

/// Main shell wrapper.
///
/// Previously contained a bottom navigation bar.
/// Now acts as a simple pass-through for the child route.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
