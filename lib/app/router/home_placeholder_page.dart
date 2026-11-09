import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

/// Holds `/` until the catalog arrives: the app title, centred inside the shell, which supplies the `Scaffold`.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(S.of(context).app_title));
  }
}
