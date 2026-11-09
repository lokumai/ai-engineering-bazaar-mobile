import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/dev_console/dev_console_overlay.dart';

/// The frame of every page inside the router's ShellRoute.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DevConsoleShortcut(
      child: Scaffold(body: SafeArea(child: child)),
    );
  }
}
