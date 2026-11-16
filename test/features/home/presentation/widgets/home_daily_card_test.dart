@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card_cubit.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/widgets.dart' show Locale, ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

HeadingBlock _h(String id, String text) => HeadingBlock(
  depth: 2,
  id: id,
  mark: null,
  inlines: [TextInline(text: text)],
);

/// The first day of the count: the card's first module, `alpha/first`, at its first section.
final _dayZero = Clock.fixed(DateTime(1970));

final _card = find.byKey(const ValueKey('home-daily-card'));

/// A course whose every module document is the same written module of two sections.
MockContentRepository _course() {
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer(
    (_) async => testDoc(
      title: 'First Module',
      body: [
        _p('An opening.'),
        _h('why', 'Why tools'),
        _p('Models call tools. They read what comes back.'),
        _h('how', 'How a call runs'),
        _p('The model names a tool.'),
      ],
    ),
  );
  return repository;
}

Future<GoRouter> _pumpHome(WidgetTester tester, {MockContentRepository? repository, Locale? locale}) async {
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      content: readyContentBloc(),
      record: readyRecordBloc(),
      repository: repository ?? _course(),
      locale: locale ?? const Locale('en'),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Home opens on the day\'s card: a section\'s heading, its first sentences and its module', (
    tester,
  ) async {
    await withClock(_dayZero, () async {
      await _pumpHome(tester);

      expect(_card, findsOneWidget);
      for (final text in [
        'Today\'s card',
        'Why tools',
        'Models call tools. They read what comes back.',
        'First Module',
      ]) {
        expect(
          find.descendant(of: _card, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(
        find.bySemanticsLabel('Today\'s card: Why tools. Models call tools. They read what comes back. First Module'),
        findsOneWidget,
      );
      await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
    });
  });

  testWidgets('the card says what it is in Turkish', (tester) async {
    await withClock(_dayZero, () async {
      await _pumpHome(tester, locale: const Locale('tr'));

      expect(find.descendant(of: _card, matching: find.text('Bugünün kartı')), findsOneWidget);
    });
  });

  testWidgets('a tap opens the module at the card\'s section', (tester) async {
    await withClock(_dayZero, () async {
      final router = await _pumpHome(tester);

      await tester.tap(_card);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/courses/alpha/first');
      expect(ReaderTarget.of(router.state.extra).fragment, 'why');
    });
  });

  testWidgets('a module that cannot be read leaves Home without a card', (tester) async {
    await withClock(_dayZero, () async {
      await _pumpHome(tester, repository: missingContentRepository());

      expect(_card, findsNothing);
      expect(find.text('Later on'), findsOneWidget, reason: 'the rest of Home is there');
    });
  });

  group('DailyCardCubit', () {
    test('shows nothing for no choice', () async {
      final cubit = DailyCardCubit(repository: missingContentRepository());
      await cubit.load(null);
      expect(cubit.state, const DailyCardNone());
    });

    test('waits for the document, then shows nothing when it cannot be read', () async {
      final cubit = DailyCardCubit(repository: missingContentRepository());
      expect(cubit.state, const DailyCardLoading());
      await cubit.load(const DailyChoice(moduleKey: 'alpha/first', docPath: 'missing.json', turn: 0));
      expect(cubit.state, const DailyCardNone());
    });
  });
}
