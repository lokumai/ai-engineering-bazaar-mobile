@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

/// The module read aloud on a thin bar over the navigation while the reader is elsewhere (the owner, 2026-11-18).

/// A phone that says the texts handed to it until a stop.
final class _Voice implements ISpeech {
  final handed = <List<String>>[];
  int stops = 0;
  Completer<void>? _saying;
  void Function(int index)? _onPart;

  /// The phone reads every text handed last to its end.
  void readAll() {
    for (var i = 0; i < handed.last.length; i++) {
      _onPart?.call(i);
    }
    final saying = _saying;
    _saying = null;
    saying?.complete();
  }

  @override
  Future<bool> canSpeak(String language) async => true;

  @override
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
    String? noticeLanguage,
  }) {
    handed.add(texts);
    _onPart = onPart;
    return (_saying = Completer<void>()).future;
  }

  @override
  Stream<void> get interruptions => const Stream.empty();

  @override
  Stream<void> get resumes => const Stream.empty();

  @override
  Future<void> show(ShownReading? reading) async {}

  @override
  Future<void> stop() async {
    stops++;
    final saying = _saying;
    _saying = null;
    saying?.complete();
  }
}

final _bar = find.byKey(const ValueKey('listen-bar'));

/// The completion toggles sent to [record] since the last look.
List<CompletionToggled> _toggles(RecordBloc record) {
  try {
    return [
      for (final event in verify(() => record.add(captureAny())).captured)
        if (event is CompletionToggled) event,
    ];
  } on TestFailure {
    return const [];
  }
}

final _band = find.byKey(const ValueKey('home-continue-band'));

Future<(GoRouter, _Voice)> _pump(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.android,
  RecordBloc? record,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer(
    (_) async => testDoc(
      title: 'Lanterns',
      body: [
        for (var i = 0; i < 6; i++) ParagraphBlock(inlines: [TextInline(text: 'Part $i.')], lead: false),
      ],
    ),
  );
  final voice = _Voice();
  final router = AppRouterFactory(initialLocation: '/courses/alpha/first').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(router: router, repository: repository, speech: voice, platform: platform, record: record),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('reader-listen')));
  await tester.pumpAndSettle();
  return (router, voice);
}

void main() {
  testWidgets('on another page the bar holds the module read aloud; its title opens it, Stop ends it', (tester) async {
    final (router, voice) = await _pump(tester);
    expect(_bar, findsNothing, reason: 'on the module its player stands at the foot');

    router.go('/practice');
    await tester.pumpAndSettle();
    expect(_bar, findsOneWidget);
    expect(find.descendant(of: _bar, matching: find.text('Lanterns')), findsOneWidget);
    expect(
      tester.getRect(_bar).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top + 0.5),
      reason: 'over the navigation',
    );
    expect(tester.getSize(_bar).height, lessThanOrEqualTo(52), reason: 'thin');

    await tester.tap(find.byKey(const ValueKey('listen-bar-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: _bar, matching: find.byTooltip('Play')),
      findsOneWidget,
      reason: 'paused from the bar',
    );

    await tester.tap(find.byKey(const ValueKey('listen-bar-open')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/courses/alpha/first');
    expect(_bar, findsNothing);
    expect(find.byKey(const ValueKey('listen-player')), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    expect(_band, findsNothing, reason: 'the bar takes the band\'s place while it shows (the owner, 2026-11-18)');
    final stops = voice.stops;
    await tester.tap(find.byKey(const ValueKey('listen-bar-stop')));
    await tester.pumpAndSettle();
    expect(_bar, findsNothing);
    expect(_band, findsOneWidget, reason: 'the band is back');
    expect(voice.stops, greaterThan(stops));
  });

  testWidgets('paused and left a while, the bar leaves for the band; back on the module, Listen goes on from where it '
      'was (the owner, 2026-11-18)', (tester) async {
    final (router, voice) = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('listen-next')));
    await tester.pumpAndSettle();
    expect(voice.handed.last, hasLength(5), reason: 'on the second part');
    await tester.tap(find.byKey(const ValueKey('listen-toggle')));
    await tester.pumpAndSettle();

    router.go('/');
    await tester.pumpAndSettle();
    expect(_bar, findsOneWidget, reason: 'a pause just made keeps the bar');
    expect(_band, findsNothing);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(_bar, findsNothing);
    expect(_band, findsOneWidget);

    router.go('/courses/alpha/first');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('listen-player')), findsNothing);
    final listen = find.byKey(const ValueKey('reader-listen'));
    expect(find.descendant(of: listen, matching: find.text('Resume listening')), findsOneWidget);
    await tester.tap(listen);
    await tester.pumpAndSettle();
    expect(voice.handed.last, hasLength(5), reason: 'from the second part, not the head');
    expect(find.byKey(const ValueKey('listen-player')), findsOneWidget);
  });

  testWidgets(
    'heard whole on another tab, the module is marked completed with a note and Undo (the owner, 2026-11-18)',
    (tester) async {
      final record = readyRecordBloc();
      final (router, voice) = await _pump(tester, record: record);
      router.go('/');
      await tester.pumpAndSettle();
      voice.readAll();
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('listen-completed'));
      expect(find.descendant(of: note, matching: find.text('Marked as completed')), findsOneWidget);
      expect(_toggles(record), hasLength(1));
      expect(_bar, findsNothing);
      await tester.tap(find.descendant(of: note, matching: find.text('Undo')));
      await tester.pumpAndSettle();
      expect(_toggles(record), hasLength(1), reason: 'Undo sends the toggle again');
    },
  );

  testWidgets('a module already completed and heard whole is left as it is', (tester) async {
    final record = readyRecordBloc(signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-09T10:00:00.000Z'));
    final (_, voice) = await _pump(tester, record: record);
    voice.readAll();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('listen-completed')), findsNothing);
    expect(_toggles(record), isEmpty, reason: 'a toggle would take its completion away');
  });

  testWidgets("over the navigation the module's player keeps no room for the screen's foot (the owner, 2026-11-18)", (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    await _pump(tester);
    final player = find.byKey(const ValueKey('listen-player'));
    expect(tester.getSize(player).height, lessThanOrEqualTo(56), reason: 'one thin row');
    expect(tester.getRect(player).bottom, closeTo(tester.getRect(find.byType(NavigationBar)).top, 1));
  });

  testWidgets('the bar meets the platform guidelines', (tester) async {
    final (router, _) = await _pump(tester, platform: defaultTargetPlatform);
    router.go('/');
    await tester.pumpAndSettle();
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
