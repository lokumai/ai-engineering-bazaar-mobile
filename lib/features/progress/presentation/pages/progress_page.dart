import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/progress_view.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The progress page at `/profile` (web `src/app/profile/page.tsx:84-104`, Decision A8): [ProgressView] over the ready
/// content. The other content states draw nothing; they never mount, since the app gate mounts the router only once the
/// content is ready.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => ProgressView(index: index),
      ContentLoading() || ContentBroken() => const SizedBox.shrink(),
    };
  }
}
