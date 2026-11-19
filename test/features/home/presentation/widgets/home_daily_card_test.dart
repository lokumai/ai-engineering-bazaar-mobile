@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card_cubit.dart';
import 'package:ai_engineering_bazaar/features/home/application/daily_card.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/widgets.dart' show Locale, Offset, Scrollable, Size, Text, ValueKey;
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

/// A course whose module documents are titled by their key, so the card says which module it is from.
MockContentRepository _titledCourse() {
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((invocation) async {
    final path = invocation.positionalArguments.single as String;
    return testDoc(
      title: 'Module ${path.split('/').skip(3).take(2).join('/')}',
      body: [_p('An opening.'), _h('why', 'Why tools'), _p('Models call tools.')],
    );
  });
  return repository;
}

Future<GoRouter> _pumpHome(
  WidgetTester tester, {
  MockContentRepository? repository,
  Locale? locale,
  RecordBloc? record,
  ReadingPlacesBloc? places,
}) async {
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(
      router: router,
      content: readyContentBloc(),
      record: record ?? readyRecordBloc(),
      repository: repository ?? _course(),
      locale: locale ?? const Locale('en'),
      places: places,
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
      for (final text in ['Why tools', 'Models call tools. They read what comes back.', 'First Module']) {
        expect(
          find.descendant(of: _card, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(
        find.bySemanticsLabel('Why tools. Models call tools. They read what comes back. First Module'),
        findsOneWidget,
      );
      expect(find.text('Today\'s card'), findsNothing, reason: 'it has no name of its own (plan 14.1)');
      expect(
        tester.widget<BazaarCard>(_card).accent,
        isNotNull,
        reason: "its level's hue along its top, the card the Apprentice shows keeps it (the owner, 2026-11-18)",
      );
      await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
    });
  });

  testWidgets('Show another brings the next card in turn, the last one standing while it is read (plan 14.1)', (
    tester,
  ) async {
    await withClock(_dayZero, () async {
      final repository = _titledCourse();
      await _pumpHome(tester, repository: repository);
      expect(find.descendant(of: _card, matching: find.text('Module alpha/first')), findsOneWidget);
      final slow = Completer<ModuleDoc>();
      when(() => repository.readModuleDoc(any())).thenAnswer((_) => slow.future);

      await tester.tap(find.byKey(const ValueKey('home-daily-another')));
      await tester.pump();
      expect(
        find.descendant(of: _card, matching: find.text('Module alpha/first')),
        findsOneWidget,
        reason: 'the last card stays while the next is read, so Home does not jump',
      );
      slow.complete(
        testDoc(
          title: 'Module alpha/second',
          body: [_p('An opening.'), _h('why', 'Why tools'), _p('Models call tools.')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: _card, matching: find.text('Module alpha/second')), findsOneWidget);
    });
  });

  testWidgets('Show another is an icon in the corner, named in Turkish (the owner, 2026-11-18)', (tester) async {
    await withClock(_dayZero, () async {
      await _pumpHome(tester, locale: const Locale('tr'));

      expect(find.byTooltip('Başka göster'), findsOneWidget);
      expect(find.text('Başka göster'), findsNothing, reason: 'no line of its own under the card');
      final icon = tester.getRect(find.byKey(const ValueKey('home-daily-another')));
      final card = tester.getRect(_card);
      expect(icon.top - card.top, lessThan(16), reason: 'at the top');
      expect(icon.right, greaterThan(card.right - 60), reason: 'at the end');
    });
  });

  testWidgets('a swipe across the card brings another; a slow drag does not (the owner, 2026-11-18)', (tester) async {
    await withClock(_dayZero, () async {
      await _pumpHome(tester, repository: _titledCourse());
      expect(find.descendant(of: _card, matching: find.text('Module alpha/first')), findsOneWidget);

      await tester.timedDrag(_card, const Offset(-120, 0), const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: _card, matching: find.text('Module alpha/first')),
        findsOneWidget,
        reason: 'slow',
      );

      await tester.fling(_card, const Offset(-200, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.descendant(of: _card, matching: find.text('Module alpha/second')), findsOneWidget);
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

  // The owner, on the phone (2026-11-17): a module opened from the day's card and scrolled came back as Continue
  // reading. A look at the day's card is not the module being read.
  testWidgets('a module opened from the card keeps no place, however far it is scrolled', (tester) async {
    await withClock(_dayZero, () async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = missingContentRepository();
      when(() => repository.readModuleDoc(any())).thenAnswer(
        (_) async => testDoc(
          title: 'First Module',
          body: [
            _p('An opening.'),
            _h('why', 'Why tools'),
            _p('Models call tools. They read what comes back.'),
            for (var i = 0; i < 60; i++) _p('Paragraph $i of a long section, long enough to wrap on a phone.'),
          ],
        ),
      );
      final places = ReadingPlacesBloc(store: MemoryReadingPlaceStore())..add(const ReadingPlacesStarted());
      addTearDown(places.close);
      final router = await _pumpHome(tester, repository: repository, places: places);

      await tester.tap(_card);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/courses/alpha/first');
      await tester.drag(
        find.text('Paragraph 3 of a long section, long enough to wrap on a phone.'),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(places.state.of(Track.engineers, 'alpha/first'), isNull);
    });
  });

  testWidgets('a module that cannot be read leaves Home without a card', (tester) async {
    await withClock(_dayZero, () async {
      await _pumpHome(tester, repository: missingContentRepository());

      expect(_card, findsNothing);
      expect(find.text('Later on'), findsOneWidget, reason: 'the rest of Home is there');
    });
  });

  // The owner, 2026-11-16: the card turned to another module once its module was finished, and a Home left open
  // overnight kept the day before.
  testWidgets('finished during the day, the card stays and says so', (tester) async {
    final day = Clock.fixed(DateTime(2026, 11, 16, 10));
    await withClock(day, () async {
      final states = StreamController<RecordState>();
      addTearDown(states.close);
      final record = MockRecordBloc();
      RecordReady ready(RecordData data) => RecordReady(
        record: data,
        writeState: const WriteSaved(),
        quarantine: null,
        quarantineKept: false,
        launchReadFailed: false,
        undo: null,
      );
      whenListen(record, states.stream, initialState: ready(RecordData.empty));
      await _pumpHome(tester, repository: _titledCourse(), record: record);
      final module = tester.widget<Text>(find.descendant(of: _card, matching: find.textContaining('Module '))).data!;
      expect(find.byKey(const ValueKey('home-daily-completed')), findsNothing);

      final key = module.substring('Module '.length);
      final finished = signOff(RecordData.empty, key, 'abc1234', DateTime(2026, 11, 16, 9).toUtc().toIso8601String());
      states.add(ready(finished));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: _card, matching: find.text(module)),
        findsOneWidget,
        reason: 'the same module',
      );
      expect(find.byKey(const ValueKey('home-daily-completed')), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });
  });

  testWidgets('Home left open over midnight shows the new day\'s card', (tester) async {
    var now = DateTime(2026, 11, 16, 23, 59);
    await withClock(Clock(() => now), () async {
      await _pumpHome(tester, repository: _titledCourse());
      String module() =>
          tester.widget<Text>(find.descendant(of: _card, matching: find.textContaining('Module '))).data!;
      final before = module();

      now = DateTime(2026, 11, 17, 0, 1);
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();

      expect(module(), isNot(before));
    });
  });

  testWidgets('scrolled away and back, the card is whole at once, so Home does not jump', (tester) async {
    // A short screen, so the card leaves the list's reach at Home's foot and the list lets it go.
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await withClock(_dayZero, () async {
      final repository = _course();
      await _pumpHome(tester, repository: repository);
      expect(_card, findsOneWidget);
      final home = find.byType(Scrollable).first;
      // What Home read to open: the day's module, and Practice's notes for the review row.
      clearInteractions(repository);

      await tester.drag(home, const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(_card, findsNothing, reason: 'Home must be long enough to let the card go');

      await tester.drag(home, const Offset(0, 5000));
      await tester.pump();

      expect(find.descendant(of: _card, matching: find.text('Why tools')), findsOneWidget);
      verifyNever(() => repository.readModuleDoc(any()));
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
