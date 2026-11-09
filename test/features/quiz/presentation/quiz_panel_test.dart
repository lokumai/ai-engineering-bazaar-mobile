@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';

const items = [
  QuizItem(question: 'Q1', options: ['One', 'Two', 'Three', 'Four'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two', 'Three', 'Four'], answer: 1, explain: 'E2'),
  QuizItem(question: 'Q3', options: ['One', 'Two', 'Three', 'Four'], answer: 2, explain: 'E3'),
];

/// The panel over [quiz] in a scrolling page of the Bazaar theme for [platform].
Widget panelApp(List<QuizItem> quiz, {TargetPlatform platform = TargetPlatform.android}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: bazaarTheme(brightness: Brightness.light, platform: platform),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: QuizPanel(items: quiz),
    ),
  ),
);

/// Pumps [panelApp] on a 390x844 surface.
Future<void> pumpPanel(
  WidgetTester tester,
  List<QuizItem> quiz, {
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(panelApp(quiz, platform: platform));
}

/// Opens or closes the panel by its title.
Future<void> toggle(WidgetTester tester) async {
  await tester.tap(find.text('Questions on this module'));
  await tester.pumpAndSettle();
}

/// Pumps the panel over [items] and opens it.
Future<void> open(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android}) async {
  await pumpPanel(tester, items, platform: platform);
  await toggle(tester);
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

VoidCallback? pressed<T extends ButtonStyleButton>(WidgetTester tester, String label) =>
    tester.widget<T>(find.widgetWithText(T, label)).onPressed;

void main() {
  testWidgets('the panel starts collapsed', (tester) async {
    await pumpPanel(tester, items);

    expect(find.text('Questions on this module'), findsOneWidget);
    expect(find.text('3 questions on the main points of this module'), findsOneWidget);
    expect(find.text('Question 1 of 3'), findsNothing);
  });

  testWidgets('opening the panel shows the first question', (tester) async {
    await open(tester);

    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
  });

  testWidgets('a wrong answer locks the question and names the right letter', (tester) async {
    await open(tester);

    expect(find.text('Q1'), findsOneWidget);
    for (final letter in ['A', 'B', 'C', 'D']) {
      expect(find.text(letter), findsOneWidget);
    }
    expect(pressed<FilledButton>(tester, 'Next'), isNull);
    final verdict = find.byKey(const Key('quiz-verdict'));
    expect(verdict, findsOneWidget, reason: 'the live region exists before the answer');

    await tapText(tester, 'Two');
    expect(find.text('Not this one. The answer is A.'), findsOneWidget);
    expect(find.text('E1'), findsOneWidget);
    expect(pressed<FilledButton>(tester, 'Next'), isNotNull);

    await tapText(tester, 'One');
    expect(find.text('Correct.'), findsNothing);
    expect(find.text('Not this one. The answer is A.'), findsOneWidget);

    expect(tester.getSemantics(verdict), matchesSemantics(isLiveRegion: true));
    expect(
      tester.getSemantics(find.text('Two')),
      matchesSemantics(
        isInMutuallyExclusiveGroup: true,
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        label: 'B Two',
      ),
    );
    expect(
      tester.getSemantics(find.text('One')),
      matchesSemantics(
        isInMutuallyExclusiveGroup: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        label: 'A One',
      ),
    );
  });

  testWidgets('a right answer says Correct.', (tester) async {
    await open(tester);

    await tapText(tester, 'One');

    expect(find.text('Correct.'), findsOneWidget);
    expect(find.text('E1'), findsOneWidget);
    expect(find.textContaining('Not this one'), findsNothing);
  });

  testWidgets('results, recap, back and start over', (tester) async {
    await open(tester);

    await tapText(tester, 'One');
    await tapText(tester, 'Next');
    expect(find.text('Question 2 of 3'), findsOneWidget);
    await tapText(tester, 'Four');
    await tapText(tester, 'Next');
    expect(find.text('Question 3 of 3'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Next'), findsNothing);
    expect(pressed<FilledButton>(tester, 'See results'), isNull);
    await tapText(tester, 'Three');
    await tapText(tester, 'See results');

    final count = find.text('2 of 3');
    expect(count, findsOneWidget);
    expect(tester.widget<Text>(count).style?.fontWeight, FontWeight.w700);
    expect(find.text('answered correctly'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('quiz-score'))),
      isSemantics(isLiveRegion: true, label: '2 of 3 answered correctly'),
    );
    final recap = {'Q1': 'Q1, correct', 'Q2': 'Q2, not correct', 'Q3': 'Q3, correct'};
    for (final MapEntry(key: question, value: label) in recap.entries) {
      expect(tester.getSemantics(find.text(question)), isSemantics(isButton: true, hasTapAction: true, label: label));
    }
    expect(tester.getTopLeft(find.text('Q1')).dy, lessThan(tester.getTopLeft(find.text('Q2')).dy));
    expect(tester.getTopLeft(find.text('Q2')).dy, lessThan(tester.getTopLeft(find.text('Q3')).dy));

    await tapText(tester, 'Q2');
    expect(find.text('Question 2 of 3'), findsOneWidget);
    expect(find.text('Not this one. The answer is B.'), findsOneWidget);

    await tapText(tester, 'Next');
    await tapText(tester, 'See results');
    await tapText(tester, 'Back to the questions');
    expect(find.text('Question 3 of 3'), findsOneWidget);
    expect(find.text('Correct.'), findsOneWidget);

    await tapText(tester, 'Start over');
    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text('Correct.'), findsNothing);
    expect(find.textContaining('Not this one'), findsNothing);
    expect(pressed<FilledButton>(tester, 'Next'), isNull);
  });

  testWidgets('Start over on the results clears the answers', (tester) async {
    await pumpPanel(tester, items.sublist(0, 1));
    await toggle(tester);

    await tapText(tester, 'Two');
    await tapText(tester, 'See results');
    expect(find.text('0 of 1'), findsOneWidget);

    await tapText(tester, 'Start over');
    expect(find.text('Question 1 of 1'), findsOneWidget);
    expect(find.textContaining('Not this one'), findsNothing);
  });

  testWidgets('Previous is disabled on the first question', (tester) async {
    await open(tester);

    expect(pressed<OutlinedButton>(tester, 'Previous'), isNull);

    await tapText(tester, 'One');
    await tapText(tester, 'Next');
    expect(pressed<OutlinedButton>(tester, 'Previous'), isNotNull);

    await tapText(tester, 'Previous');
    expect(find.text('Question 1 of 3'), findsOneWidget);
  });

  testWidgets('the question takes the focus when it changes', (tester) async {
    await open(tester);

    await tapText(tester, 'One');
    await tapText(tester, 'Next');

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'quiz-question');
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(find.descendant(of: find.byWidget(focused.widget), matching: find.text('Q2')), findsOneWidget);
  });

  testWidgets('the answers survive collapsing the panel', (tester) async {
    await open(tester);

    await tapText(tester, 'Two');
    await toggle(tester);
    expect(find.text('Not this one. The answer is A.'), findsNothing);

    await toggle(tester);
    expect(find.text('Not this one. The answer is A.'), findsOneWidget);
  });

  testWidgets('buildQuizPanel builds the panel over the items', (tester) async {
    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = buildQuizPanel(context, items);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(built, isA<QuizPanel>().having((panel) => panel.items, 'items', items));
  });

  testWidgets('the open panel works at text scale 2.0', (tester) async {
    await pumpAtTextScale(tester, panelApp(items), scale: 2.0);
    await toggle(tester);

    expect(tester.takeException(), isNull);
    for (final target in ['One', 'Two', 'Three', 'Four', 'Next', 'Start over']) {
      await tester.ensureVisible(find.text(target));
      await tester.pumpAndSettle();
      expectHittable(tester, find.text(target));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the open panel meets the platform guidelines before an answer', (tester) async {
    await open(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('the open panel meets the platform guidelines after an answer', (tester) async {
    await open(tester, platform: defaultTargetPlatform);
    await tapText(tester, 'Two');

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('the results meet the platform guidelines', (tester) async {
    await pumpPanel(tester, items.sublist(0, 1), platform: defaultTargetPlatform);
    await toggle(tester);
    await tapText(tester, 'One');
    await tapText(tester, 'See results');

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
