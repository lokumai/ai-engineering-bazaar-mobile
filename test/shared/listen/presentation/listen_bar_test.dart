@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
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

  @override
  Future<bool> canSpeak(String language) async => true;

  @override
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
  }) {
    handed.add(texts);
    return (_saying = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    final saying = _saying;
    _saying = null;
    saying?.complete();
  }
}

final _bar = find.byKey(const ValueKey('listen-bar'));

Future<(GoRouter, _Voice)> _pump(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android}) async {
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
  await tester.pumpWidget(bazaarTestApp(router: router, repository: repository, speech: voice, platform: platform));
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
    final stops = voice.stops;
    await tester.tap(find.byKey(const ValueKey('listen-bar-stop')));
    await tester.pumpAndSettle();
    expect(_bar, findsNothing);
    expect(voice.stops, greaterThan(stops));
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
