@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_gate.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_view.dart';
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
final _enter = find.byKey(const Key('welcome-enter'));

ContentBloc _content() {
  final content = MockContentBloc();
  whenListen(
    content,
    const Stream<ContentState>.empty(),
    initialState: ContentReady(
      index: catalogFixtureIndex(),
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
}) => RepositoryProvider<IWelcomeStore>.value(
  value: store,
  child: MultiBlocProvider(
    providers: [
      BlocProvider<ContentBloc>.value(value: _content()),
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
      home: WelcomeGate(onFinished: onFinished, child: _app),
    ),
  ),
);

double _opacityAbove(WidgetTester tester, Finder finder) =>
    tester.widget<Opacity>(find.ancestor(of: finder, matching: find.byType(Opacity)).first).opacity;

/// The left lamp's turn: the sine in its rotation, 0 at rest.
double _lampTurn(WidgetTester tester) => tester
    .widget<Transform>(
      find.ancestor(of: find.image(const AssetImage(WelcomeArt.lampLeft)), matching: find.byType(Transform)).first,
    )
    .transform
    .storage[1];

void main() {
  testWidgets('the first launch shows Welcome, asks the track, and the choice opens the app and records it', (
    tester,
  ) async {
    final store = _MemoryWelcomeStore();
    final track = TrackCubit();
    addTearDown(track.close);
    final finished = <Track>[];
    await tester.pumpWidget(_gate(store, track: track, onFinished: finished.add));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeView), findsOneWidget);
    expect(find.text('the app'), findsNothing);
    expect(find.text('AI engineering, written by the people who build it.'), findsOneWidget);
    expect(find.text('Enter the bazaar'), findsOneWidget);
    expect(find.text('Lokum AI'), findsOneWidget);

    await tester.ensureVisible(_enter);
    await tester.pumpAndSettle();
    await tester.tap(_enter);
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeTrackView), findsOneWidget);
    expect(find.text('How would you like to read?'), findsOneWidget);
    expect(store.wasSeen, isFalse, reason: 'not before a track is chosen');
    final everyone = find.byKey(WelcomeTrackView.optionKey(Track.everyone));
    expect(tester.getSemantics(everyone), isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false));
    await tester.tap(everyone);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(everyone), isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true));
    await tester.ensureVisible(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(WelcomeView), findsNothing);
    expect(store.wasSeen, isTrue);
    expect(track.state, Track.everyone);
    expect(finished, [Track.everyone], reason: 'the app lands on that catalog (plan 1T)');
  });

  testWidgets('a later launch opens the app directly', (tester) async {
    final finished = <Track>[];
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(wasSeen: true), onFinished: finished.add));
    await tester.pumpAndSettle();

    expect(finished, isEmpty, reason: 'it stays where the app opens, Home (plan 1T)');
    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(WelcomeView), findsNothing);
  });

  testWidgets('the headline is a header and the pictures say nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_gate(_MemoryWelcomeStore()));
    await tester.pumpAndSettle();

    const headline = 'AI engineering, written by the people who build it.';
    expect(tester.getSemantics(find.text(headline)), isSemantics(label: headline, isHeader: true));
    expect(find.bySemanticsLabel(RegExp('gate|cast|lamp', caseSensitive: false)), findsNothing);
    handle.dispose();
  });

  testWidgets('the entrance moves into place over its time', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore()));
    await tester.pump();
    await tester.pump();

    expect(_opacityAbove(tester, _enter), lessThan(1));
    await tester.pump(WelcomeView.entrance);
    expect(_opacityAbove(tester, _enter), 1);
  });

  testWidgets('after the entrance the scene stays alive for a while, then rests (plan 1S)', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore()));
    // Frame by frame through the entrance and a little of the scene's life, as a device draws it.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_lampTurn(tester), isNot(closeTo(0, 1e-4)), reason: 'the lamp sways');
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(WelcomeView.ambience);
    await tester.pump();
    expect(_lampTurn(tester), closeTo(0, 1e-6), reason: 'and comes to rest');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('under reduced motion everything is in place at once', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(), reducedMotion: true));
    await tester.pump();
    await tester.pump();

    expect(_opacityAbove(tester, _enter), 1);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(WelcomeView.entrance + WelcomeView.ambience);
    expect(_lampTurn(tester), closeTo(0, 1e-6), reason: 'nothing sways either');
  });

  testWidgets('the track step chooses the language too, at once (plan 1S)', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_enter);
    await tester.pumpAndSettle();
    await tester.tap(_enter);
    await tester.pumpAndSettle();

    final language = tester.element(find.byType(WelcomeTrackView)).read<LanguageCubit>();
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('فارسی'), findsOneWidget);
    await tester.tap(find.byKey(WelcomeTrackView.languageKey('tr')));
    await tester.pump();

    expect(language.state, 'tr');
  });

  testWidgets('text scale 2.0 keeps the way in reachable', (tester) async {
    await pumpAtTextScale(tester, _gate(_MemoryWelcomeStore()), scale: 2.0);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_enter);
    await tester.pumpAndSettle();
    expectHittable(tester, _enter);
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(), platform: defaultTargetPlatform));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
