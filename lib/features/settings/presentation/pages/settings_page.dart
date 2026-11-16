import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.openDevConsole, this.feedback = false, this.wardrobePicture});

  /// Passed to [SettingsScreen.openDevConsole].
  final void Function(BuildContext context)? openDevConsole;

  /// Passed to [SettingsScreen.feedback].
  final bool feedback;

  /// Passed to [SettingsScreen.wardrobePicture].
  final Widget Function(double side)? wardrobePicture;

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(openDevConsole: openDevConsole, feedback: feedback, wardrobePicture: wardrobePicture);
  }
}
