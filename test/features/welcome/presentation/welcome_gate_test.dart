@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_gate.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_track_view.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/catalog_fixture_index.dart';

final class _MemoryWelcomeStore implements IWelcomeStore {
  _MemoryWelcomeStore({this.wasSeen = false});

  bool wasSeen;

  @override
  Future<bool> seen() async => wasSeen;

  @override
  Future<void> markSeen() async => wasSeen = true;
}

const _app = Text('the app');

/// The story step as the app would pass it: a button that goes on.
const _storyDoneKey = Key('story-done');

Widget _story(VoidCallback onDone) => Scaffold(
  body: Center(
    child: TextButton(key: _storyDoneKey, onPressed: onDone, child: const Text('the story')),
  ),
);

ContentBloc _content({bool story = true}) {
  final content = MockContentBloc();
  whenListen(
    content,
    const Stream<ContentState>.empty(),
    initialState: ContentReady(
      index: catalogFixtureIndex(story: story ? const {'en': 'api/v1/story/en.json'} : const {}),
      origin: ContentOrigin.bundled,
      notice: null,
      refresh: const RefreshUpToDate(),
    ),
  );
  return content;
}

Widget _gate(
  IWelcomeStore store, {
  TargetPlatform platform = TargetPlatform.android,
  bool reducedMotion = false,
  TrackCubit? track,
  ValueChanged<Track>? onFinished,
  bool story = true,
}) => RepositoryProvider<IWelcomeStore>.value(
  value: store,
  child: MultiBlocProvider(
    providers: [
      BlocProvider<ContentBloc>.value(value: _content(story: story)),
      if (track != null) BlocProvider<TrackCubit>.value(value: track) else BlocProvider(create: (_) => TrackCubit()),
      BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
    ],
    child: MaterialApp(
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
      builder: (context, child) => reducedMotion
          ? MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!)
          : child!,
      home: WelcomeGate(story: _story, onFinished: onFinished, child: _app),
    ),
  ),
);

void main() {
  testWidgets('the first launch asks the language and the track, then tells the story, then opens the app (plan 3.5)', (
    tester,
  ) async {
    final store = _MemoryWelcomeStore();
    final track = TrackCubit();
    addTearDown(track.close);
    final finished = <Track>[];
    await tester.pumpWidget(_gate(store, track: track, onFinished: finished.add));
    await tester.pumpAndSettle();

    expect(find.text('the app'), findsNothing);
    expect(find.text('the story'), findsNothing, reason: 'the language comes first, so the story is told in it');
    expect(find.byType(WelcomeTrackView), findsOneWidget);
    expect(find.text('How would you like to read?'), findsOneWidget);
    final everyone = find.byKey(WelcomeTrackView.optionKey(Track.everyone));
    expect(tester.getSemantics(everyone), isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false));
    await tester.ensureVisible(everyone);
    await tester.pumpAndSettle();
    await tester.tap(everyone);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(everyone), isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true));
    final start = find.byKey(const Key('welcome-start'));
    expect(find.descendant(of: start, matching: find.text('On to the story')), findsOneWidget);
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(find.text('the story'), findsOneWidget);
    expect(track.state, Track.everyone, reason: 'the track is kept as soon as it is chosen');
    expect(store.wasSeen, isFalse, reason: 'not before the story is read or skipped');
    expect(finished, isEmpty);
    await tester.tap(find.byKey(_storyDoneKey));
    await tester.pumpAndSettle();

    expect(find.text('the app'), findsOneWidget);
    expect(store.wasSeen, isTrue);
    expect(finished, [Track.everyone], reason: 'the app lands on that catalog (plan 1T)');
  });

  testWidgets('a later launch opens the app directly', (tester) async {
    final finished = <Track>[];
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(wasSeen: true), onFinished: finished.add));
    await tester.pumpAndSettle();

    expect(finished, isEmpty, reason: 'it stays where the app opens, Home (plan 1T)');
    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(WelcomeTrackView), findsNothing);
  });

  testWidgets('the track step chooses the language too, at once (plan 1S)', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(), story: false));
    await tester.pumpAndSettle();

    final language = tester.element(find.byType(WelcomeTrackView)).read<LanguageCubit>();
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('فارسی'), findsOneWidget);
    await tester.tap(find.byKey(WelcomeTrackView.languageKey('tr')));
    await tester.pump();

    expect(language.state, 'tr');
  });

  testWidgets('text scale 2.0 keeps the way on reachable', (tester) async {
    await pumpAtTextScale(tester, _gate(_MemoryWelcomeStore(), story: false), scale: 2.0);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final start = find.byKey(const Key('welcome-start'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    expectHittable(tester, start);
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(), platform: defaultTargetPlatform, story: false));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  testWidgets('content that names no story starts at the track and goes from it into the app (web D125)', (
    tester,
  ) async {
    final store = _MemoryWelcomeStore();
    final finished = <Track>[];
    await tester.pumpWidget(_gate(store, onFinished: finished.add, story: false));
    await tester.pumpAndSettle();
    expect(find.text('Start reading'), findsOneWidget, reason: 'no story to go on to');
    await tester.ensureVisible(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();

    expect(find.text('Start reading'), findsNothing, reason: 'tapped: the app is open');
    expect(find.text('the story'), findsNothing);
    expect(find.text('the app'), findsOneWidget);
    expect(store.wasSeen, isTrue);
    expect(finished, [Track.engineers]);
  });
}
