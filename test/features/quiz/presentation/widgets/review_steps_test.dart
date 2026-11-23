@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/quiz/application/review_session.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/review_card_view.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

/// Review 8, finding 9: the step dots were a Row inside a Wrap, which does not wrap a Row's children, so "Answer them
/// all" with about 21 or more wrong answers ran the dots off a phone's edge, the ringed current one with them.
void main() {
  testWidgets('forty cards keep every step dot on a 360 wide phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const term = GlossaryTerm(
      moduleKey: 'alpha/first',
      index: 0,
      name: 'Lantern',
      forms: ['Lantern'],
      definition: [TextInline(text: 'a light you carry.')],
    );
    final cards = [
      for (var i = 0; i < 40; i++)
        TermItem(
          key: 'term:engineers/alpha/first#$i',
          moduleTitle: 'First',
          term: term,
          options: const ['Wick', 'Lantern'],
          answer: 1,
        ),
    ];
    final session = ReviewSessionCubit(cards, onAnswered: (_, _) {});
    addTearDown(session.close);
    final content = readyContentBloc();
    final track = TrackCubit();
    addTearDown(track.close);

    await pumpInTheme(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: session),
          BlocProvider.value(value: content),
          BlocProvider.value(value: track),
        ],
        child: const SizedBox(height: 800, child: ReviewSessionView()),
      ),
      Brightness.light,
    );
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'no overflow');
    final dots = find.byWidgetPredicate(
      (widget) => switch (widget.key) {
        ValueKey<String>(:final value) => value.startsWith('review-step-'),
        _ => false,
      },
    );
    expect(dots, findsNWidgets(40));
    for (final dot in dots.evaluate()) {
      final box = dot.renderObject! as RenderBox;
      expect(box.localToGlobal(box.size.bottomRight(Offset.zero)).dx, lessThanOrEqualTo(360));
    }

    // Review 8, finding 15: a wrong step is a square, so right and wrong differ by more than colour.
    session.pick(0);
    await tester.pump();
    await tester.pump();
    BoxShape shape(int step) =>
        (tester
                    .widget<Container>(
                      find.descendant(of: find.byKey(ValueKey('review-step-$step')), matching: find.byType(Container)),
                    )
                    .decoration!
                as BoxDecoration)
            .shape;
    expect(shape(0), BoxShape.rectangle);
    expect(shape(1), BoxShape.circle);
  });
}
