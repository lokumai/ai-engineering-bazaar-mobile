@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/domain/speech.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

/// Listen to a module (plan 15.1).

/// A voice that says each text until the test ends it with [finish], or a stop cuts it.
final class _Voice implements ISpeech {
  _Voice({this.speaks = true});

  final bool speaks;
  final said = <String>[];
  final asked = <String>[];
  int stops = 0;
  Completer<void>? _saying;

  void finish() {
    final saying = _saying;
    _saying = null;
    saying?.complete();
  }

  @override
  Future<bool> canSpeak(String language) async {
    asked.add(language);
    return speaks;
  }

  @override
  Future<void> speak(String text, {required String language, required double rate}) {
    said.add(text);
    return (_saying = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    finish();
  }
}

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

final _body = [
  const HeadingBlock(
    depth: 2,
    id: 'why',
    mark: null,
    inlines: [TextInline(text: 'Why tools')],
  ),
  _p('Models call tools.'),
  const CodeBlock(
    language: 'py',
    lines: [
      [CodeToken(text: 'print(1)', role: null, bold: false)],
    ],
  ),
  for (var i = 0; i < 30; i++) _p('Filler paragraph number $i of the module body.'),
  _p('Far down.'),
];

final _listen = find.byKey(const ValueKey('reader-listen'));
final _toggle = find.byKey(const ValueKey('listen-toggle'));
final _next = find.byKey(const ValueKey('listen-next'));
final _marked = find.byKey(const Key('spoken-block'));

Finder _words(String text) => find.text(text, findRichText: true);

void main() {
  late MockModuleReaderBloc reader;

  setUp(() {
    reader = MockModuleReaderBloc();
    whenListen(
      reader,
      const Stream<ReaderState>.empty(),
      initialState: ReaderWritten(
        doc: testDoc(body: _body),
        entry: testModule(),
        moduleCount: 1,
      ),
    );
  });

  Future<GoRouter> pump(WidgetTester tester, ISpeech speech, {TargetPlatform platform = TargetPlatform.android}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/reader',
      routes: [
        GoRoute(
          path: '/reader',
          builder: (_, _) => BlocProvider<ModuleReaderBloc>.value(value: reader, child: const ModuleReaderView()),
        ),
        GoRoute(path: '/elsewhere', builder: (_, _) => const Text('elsewhere')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(
        router: router,
        content: readyContentBloc(testIndex(modules: [testModule()])),
        speech: speech,
        platform: platform,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

  testWidgets('no voice for the module\'s language, or none at all: no Listen', (tester) async {
    final voice = _Voice(speaks: false);
    await pump(tester, voice);
    expect(voice.asked, ['en'], reason: "the module's own language");
    expect(_listen, findsNothing);

    await pump(tester, const NoSpeech());
    expect(_listen, findsNothing);
  });

  testWidgets('Listen reads from the head, the part read marked; the player steps, pauses and stops', (tester) async {
    final voice = _Voice();
    await pump(tester, voice);

    await tester.tap(_listen);
    await tester.pumpAndSettle();
    expect(voice.said, ['Why tools.']);
    expect(find.text('1 of 33'), findsOneWidget, reason: 'the code is passed over');
    expect(rectOf(tester, _marked).contains(tester.getCenter(_words('Why tools'))), isTrue);
    expect(_listen, findsNothing, reason: 'the player stands in for it');

    voice.finish();
    await tester.pumpAndSettle();
    expect(voice.said.last, 'Models call tools.');
    expect(find.text('2 of 33'), findsOneWidget);
    expect(rectOf(tester, _marked).contains(tester.getCenter(_words('Models call tools.'))), isTrue);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('2 of 33'), findsOneWidget, reason: 'paused on its part');

    await tester.tap(find.byKey(const ValueKey('listen-speed')));
    await tester.pumpAndSettle();
    expect(find.text('1.25×'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('listen-stop')));
    await tester.pumpAndSettle();
    expect(_toggle, findsNothing);
    expect(_marked, findsNothing);
    await tester.scrollUntilVisible(_listen, -200, scrollable: find.byType(Scrollable).first);
    expect(_listen, findsOneWidget);
  });

  testWidgets('the page follows the part read down the module', (tester) async {
    await pump(tester, _Voice());
    expect(_words('Far down.').hitTestable(), findsNothing, reason: 'below the screen at first');

    await tester.tap(_listen);
    await tester.pumpAndSettle();
    await tester.tap(_toggle);
    for (var i = 0; i < 32; i++) {
      await tester.tap(_next);
      await tester.pumpAndSettle();
    }
    expect(find.text('33 of 33'), findsOneWidget);
    expect(_words('Far down.').hitTestable(), findsOneWidget);
    expect(rectOf(tester, _marked).contains(tester.getCenter(_words('Far down.'))), isTrue);
  });

  testWidgets('the reading pauses when the app leaves the screen, and stops when the module is left', (tester) async {
    final voice = _Voice();
    final router = await pump(tester, voice);
    await tester.tap(_listen);
    await tester.pumpAndSettle();

    // A hidden app draws no frames: the pause shows once it is back.
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play'), findsOneWidget);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    final stops = voice.stops;
    router.go('/elsewhere');
    await tester.pumpAndSettle();
    expect(voice.stops, greaterThan(stops));
  });

  testWidgets('the player meets the platform guidelines', (tester) async {
    await pump(tester, _Voice(), platform: defaultTargetPlatform);
    await tester.tap(_listen);
    await tester.pumpAndSettle();
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
