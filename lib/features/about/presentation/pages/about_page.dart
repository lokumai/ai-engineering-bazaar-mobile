import 'package:ai_engineering_bazaar/features/about/application/about_bloc.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_story_view.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The story of the Bazaar, from Settings (`/settings/about`; web D115, D125).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: AboutStory());
}

/// The story with its [AboutBloc], read in the app's language; [footer] goes after it (Welcome's way on, plan 3.5).
///
/// It keeps the content it was opened with; a new language reads the story again.
class AboutStory extends StatelessWidget {
  const AboutStory({super.key, this.footer});

  final Widget? footer;

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
      child: AboutStoryView(language: language, footer: footer),
    );
  }
}
