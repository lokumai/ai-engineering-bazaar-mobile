import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_bar.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:flutter/material.dart';

/// The quiz full screen's frame: the app's bar on the page ground with a close button and [title], the thin lattice
/// band under it, then [child], as every page of the shell (owner, 2026-11-10: the navy bar is gone everywhere).
class QuizFrame extends StatelessWidget {
  const QuizFrame({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BazaarBar(close: true, onBack: () => Navigator.maybePop(context), title: title),
          const LatticeBand(thin: true),
          // The bar's status strip already keeps the page clear of the status bar.
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
          ),
        ],
      ),
    );
  }
}
