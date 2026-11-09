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
}) => RepositoryProvider<IWelcomeStore>.value(
  value: store,
  child: MultiBlocProvider(
    providers: [
      BlocProvider<ContentBloc>.value(value: _content()),
      if (track != null) BlocProvider<TrackCubit>.value(value: track) else BlocProvider(create: (_) => TrackCubit()),
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
      home: const WelcomeGate(child: _app),
    ),
  ),
);

double _opacityAbove(WidgetTester tester, Finder finder) =>
    tester.widget<Opacity>(find.ancestor(of: finder, matching: find.byType(Opacity)).first).opacity;

void main() {
  testWidgets('the first launch shows Welcome, asks the track, and the choice opens the app and records it', (
    tester,
  ) async {
    final store = _MemoryWelcomeStore();
    final track = TrackCubit();
    addTearDown(track.close);
    await tester.pumpWidget(_gate(store, track: track));
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
  });

  testWidgets('a later launch opens the app directly', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(wasSeen: true)));
    await tester.pumpAndSettle();

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

  testWidgets('under reduced motion everything is in place at once', (tester) async {
    await tester.pumpWidget(_gate(_MemoryWelcomeStore(), reducedMotion: true));
    await tester.pump();
    await tester.pump();

    expect(_opacityAbove(tester, _enter), 1);
    expect(tester.hasRunningAnimations, isFalse);
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
