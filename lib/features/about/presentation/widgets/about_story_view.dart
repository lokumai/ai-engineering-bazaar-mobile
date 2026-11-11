import 'package:ai_engineering_bazaar/features/about/application/about_bloc.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/about_palette.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_film.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_ground.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The story of the Bazaar from the [AboutBloc] in context, over the whole screen: the film of it once it is read
/// ([AboutFilm]), on the opening's ground while it loads, and the way out alone when there is none to tell.
///
/// The words are the bundle's (web D125) and the pictures the web's scenes in motion (`assets/about/SOURCE.md`). The
/// story keeps its own direction, and says it is in English when the app is not.
class AboutStoryView extends StatelessWidget {
  const AboutStoryView({
    super.key,
    required this.language,
    required this.onFinished,
    required this.exit,
    required this.finishLabel,
  });

  /// The app's language, to say when the story is not written in it.
  final String language;
  final VoidCallback onFinished;
  final AboutExit exit;
  final String finishLabel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return switch (context.watch<AboutBloc>().state) {
      AboutReady(:final story) => Directionality(
        textDirection: story.dir == TextDir.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: AboutFilm(
          story: story,
          onFinished: onFinished,
          exit: exit,
          finishLabel: finishLabel,
          note: story.lang != language ? s.about_english : null,
        ),
      ),
      AboutLoading() => AboutGround(
        color: AboutPalette.groundOpening,
        child: Center(
          child: CircularProgressIndicator(color: AboutPalette.gold, semanticsLabel: s.loading),
        ),
      ),
      AboutAbsent() => _Away(onFinished: onFinished, finishLabel: finishLabel),
      AboutFailed() => _Away(onFinished: onFinished, finishLabel: finishLabel, message: s.about_failed),
    };
  }
}

/// No story to tell: [message], if any, and the way on.
class _Away extends StatelessWidget {
  const _Away({required this.onFinished, required this.finishLabel, this.message});

  final VoidCallback onFinished;
  final String finishLabel;
  final String? message;

  @override
  Widget build(BuildContext context) => AboutGround(
    color: AboutPalette.groundOpening,
    child: Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              if (message case final message?)
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AboutPalette.ink),
                ),
              FilledButton(
                key: AboutFilm.finishKey,
                onPressed: onFinished,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AboutPalette.groundDawn,
                  foregroundColor: AboutPalette.dawnTitle,
                ),
                child: Text(finishLabel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
