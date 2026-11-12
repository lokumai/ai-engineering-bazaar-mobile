import 'package:ai_engineering_bazaar/features/quiz/application/quiz_loader.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_frame.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The quiz of one module full screen at `/quiz/<level>/<module>` (plan 1AC and 1AD): opened from the Quiz tab or from
/// Home's practice, without the reader. It reads the module's quiz, then shows [QuizScreen] titled with the module;
/// closing returns to the page that opened it. Nothing is written to the record (R51); the score is kept on this device
/// (plan 1W).
class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.moduleKey});

  /// `<level>/<module>`.
  final String moduleKey;

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      // The app gate mounts the router only once the content is ready.
      final state => throw StateError('The quiz needs ready content, not $state'),
    };
    final language = context.watch<LanguageCubit>().state;
    final track = context.watch<TrackCubit>().state;
    return BlocProvider(
      // A new language or track reads the quiz again in it.
      key: ValueKey((moduleKey, language, track)),
      create: (context) =>
          QuizLoader(repository: context.read<IContentRepository>(), index: index)
            ..load(moduleKey, language, track: track),
      child: BlocBuilder<QuizLoader, QuizLoad>(
        builder: (context, state) => switch (state) {
          QuizReady(:final title, :final items) => BlocProvider(
            create: (context) => quizCubitFor(context, moduleKey, items),
            child: QuizScreen(moduleKey: moduleKey, items: items, title: title, doneLabel: S.of(context).quiz_done),
          ),
          QuizLoading() => const _Frame(child: Center(child: CircularProgressIndicator())),
          QuizMissing() || QuizUnreadable() => _Frame(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(S.of(context).quiz_unavailable, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        },
      ),
    );
  }
}

/// The quiz screen's bar around [child], while the quiz loads or when it cannot be shown.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return QuizFrame(title: S.of(context).quiz_title, child: child);
  }
}
