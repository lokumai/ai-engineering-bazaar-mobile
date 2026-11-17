import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/review_session.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_frame.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/review_card_view.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/presentation/review_pool_of.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/utils/local_day.dart';

/// Which cards a session asks.
enum ReviewKind {
  /// Today's review (plan 13.3): its cards count toward the day's five.
  today,

  /// Every question in Wrong answers (plan 13.4).
  wrong,
}

/// A Practice session full screen, over the shell (plan 13.3, 13.4): the cards of [kind], fixed when the page opens, so
/// answering one does not change the ones to come. Each answer goes to Practice's history at once; closing the page
/// keeps the answers given.
class ReviewSessionPage extends StatefulWidget {
  const ReviewSessionPage({super.key, required this.kind, this.random});

  final ReviewKind kind;

  /// Shuffles the options; a new one when null. Tests pass a seeded one.
  final Random? random;

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  /// The cards, once the notes are read.
  List<ReviewItem>? _items;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = switch (widget.kind) {
      ReviewKind.today => s.practice_today,
      ReviewKind.wrong => s.practice_wrong,
    };
    return StudyNotesLoader(
      child: QuizFrame(title: title, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final items = _items ??= _itemsNow(context);
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(S.of(context).review_empty, style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    final review = context.read<ReviewBloc>();
    final counted = widget.kind == ReviewKind.today;
    return BlocProvider(
      create: (_) => ReviewSessionCubit(
        items,
        onAnswered: (item, right) => review.add(
          ReviewAnswered(
            key: item.key,
            right: right,
            length: switch (item) {
              QuestionItem(:final length) => length,
              TermItem() => null,
            },
            inReview: counted,
          ),
        ),
      ),
      child: const ReviewSessionView(),
    );
  }

  /// The session's cards from the notes, the history and the record, or null while the notes are being read.
  List<ReviewItem>? _itemsNow(BuildContext context) {
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final pool = reviewPoolOf(context, track, language);
    final notes = context.watch<StudyNotesCubit>().state;
    if (pool == null || notes is! StudyNotesReady) return null;
    final index = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final history = context.read<ReviewBloc>().state.history;
    final keys = switch (widget.kind) {
      ReviewKind.today => pool.today(history, dayNumber(clock.now())),
      ReviewKind.wrong => pool.wrong(history),
    };
    return reviewItems(
      keys,
      notes,
      titleOf: (key) => index?.module(key)?.tracks[track]?.titleIn(language) ?? key,
      random: widget.random ?? Random(),
    );
  }
}
