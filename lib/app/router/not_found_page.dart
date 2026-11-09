import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:flutter/material.dart';

/// Shown for locations that match no route: a root page outside the shell, so no track switch is drawn. The router's
/// own error, in English, goes to the log.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: NotFoundView()));
  }
}
