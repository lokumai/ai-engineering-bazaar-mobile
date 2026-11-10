import 'package:ai_engineering_bazaar/features/about/application/about_bloc.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_film.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_story_view.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The story of the Bazaar from Settings (`/settings/about`; web D115, D125), over the whole app as a film; its close
/// button and the button at its end go back to Settings.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AboutStory(
      exit: AboutExit.close,
      finishLabel: S.of(context).about_close,
      onFinished: () => Navigator.maybePop(context),
    ),
  );
}

/// The story with its [AboutBloc], read in the app's language and told as a film; [onFinished] is the way out, by
/// [exit] at any time or by [finishLabel] at its end.
///
/// It keeps the content it was opened with; a new language reads the story again.
class AboutStory extends StatelessWidget {
  const AboutStory({super.key, required this.onFinished, required this.exit, required this.finishLabel});

  final VoidCallback onFinished;
  final AboutExit exit;
  final String finishLabel;

  @override
  Widget build(BuildContext context) {
    final index = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate shows the router and Welcome only once the content is ready.
      final state => throw StateError('The story needs ready content, not $state'),
    };
    final language = context.watch<LanguageCubit>().state;
    return BlocProvider(
      key: ValueKey(language),
      create: (context) =>
          AboutBloc(repository: context.read<IContentRepository>(), index: index)..add(AboutOpened(language: language)),
      child: AboutStoryView(language: language, onFinished: onFinished, exit: exit, finishLabel: finishLabel),
    );
  }
}
