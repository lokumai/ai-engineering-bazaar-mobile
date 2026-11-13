@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';

/// A [MockContentBloc] that stays at [ContentReady] over [index] (default [catalogFixtureIndex]) with [origin],
/// [notice] and [refresh].
MockContentBloc _contentBloc({
  BundleIndex? index,
  ContentOrigin origin = ContentOrigin.bundled,
  ContentNotice? notice,
  RefreshStatus refresh = const RefreshUpToDate(),
}) {
  final bloc = MockContentBloc();
  whenListen(
    bloc,
    const Stream<ContentState>.empty(),
    initialState: ContentReady(index: index ?? catalogFixtureIndex(), origin: origin, notice: notice, refresh: refresh),
  );
  return bloc;
}

/// [catalogFixtureIndex] published at [instant] instead.
BundleIndex _publishedAt(DateTime instant) {
  final index = catalogFixtureIndex();
  return BundleIndex(
    contentVersion: index.contentVersion,
    publishedAt: instant.toIso8601String(),
    publishedAtInstant: instant,
    tracks: index.tracks,
    diagramFont: index.diagramFont,
    diagramThemes: index.diagramThemes,
    levels: index.levels,
    modules: index.modules,
    moved: index.moved,
    files: index.files,
    images: index.images,
  );
}

/// A router whose `/settings` builds [SettingsScreen] with [openDevConsole].
GoRouter _router({void Function(BuildContext context)? openDevConsole}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, _) => SettingsScreen(openDevConsole: openDevConsole),
      ),
      GoRoute(path: '/settings/app-icon', builder: (_, _) => const Text('app icon page')),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

Future<void> _pump(
  WidgetTester tester, {
  ContentBloc? content,
  void Function(BuildContext context)? openDevConsole,
}) async {
  await tester.pumpWidget(
    bazaarTestApp(
      router: _router(openDevConsole: openDevConsole),
      content: content ?? _contentBloc(),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(registerAllFallbackValues);

  testWidgets('the track is chosen here, and kept (plan 1L)', (tester) async {
    final store = _TrackStore();
    final track = TrackCubit(store: store);
    addTearDown(track.close);
    await tester.pumpWidget(bazaarTestApp(router: _router(), content: _contentBloc(), track: track));
    await tester.pump();

    expect(find.text('Reading'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(settingsTrackKey(Track.engineers))),
      isSemantics(isSelected: true, isButton: true),
    );

    await tester.tap(find.byKey(settingsTrackKey(Track.everyone)));
    await tester.pump();

    expect(track.state, Track.everyone);
    expect(store.kept, Track.everyone);
    expect(
      tester.getSemantics(find.byKey(settingsTrackKey(Track.everyone))),
      isSemantics(isSelected: true, isButton: true),
    );
  });

  testWidgets('the language is chosen here, each named in its own language (plan 1Q)', (tester) async {
    final language = LanguageCubit();
    addTearDown(language.close);
    await tester.pumpWidget(bazaarTestApp(router: _router(), content: _contentBloc(), language: language));
    await tester.pump();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('فارسی'), findsOneWidget);
    expect(tester.getSemantics(find.byKey(settingsLanguageKey('en'))), isSemantics(isSelected: true, isButton: true));

    await tester.tap(find.byKey(settingsLanguageKey('tr')));
    await tester.pump();

    expect(language.state, 'tr');
  });

  testWidgets('the App icon row under the appearance shows the icon in use, unnamed, and opens its page', (
    tester,
  ) async {
    final appIcon = AppIconCubit(store: const _KeptIcon(BazaarIcon.noir))..load();
    addTearDown(appIcon.close);
    await tester.pumpWidget(bazaarTestApp(router: _router(), content: _contentBloc(), appIcon: appIcon));
    await tester.pump();

    final row = find.byKey(const Key('settings-app-icon'));
    expect(find.descendant(of: row, matching: find.text('App icon')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.image(AssetImage(BazaarIcon.noir.asset))), findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Noir')),
      findsNothing,
      reason: 'the picture says which',
    );
    expect(tester.getSize(find.descendant(of: row, matching: find.byType(Image))), const Size(52, 52));
    expect(tester.getSemantics(row), isSemantics(label: 'App icon, Noir', isButton: true));
    expect(
      tester.getTopLeft(row).dy,
      greaterThan(tester.getBottomLeft(find.byKey(settingsAppearanceKey(ThemeMode.dark))).dy),
      reason: 'under the appearance',
    );

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('app icon page'), findsOneWidget);
  });

  testWidgets('the appearance is Light or Dark, with Dark selected until one is chosen, whatever the phone', (
    tester,
  ) async {
    final themeChoice = ThemeChoiceCubit();
    addTearDown(themeChoice.close);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(bazaarTestApp(router: _router(), content: _contentBloc(), themeChoice: themeChoice));
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(settingsAppearanceKey(ThemeMode.dark)), matching: find.text('Dark')),
      findsOneWidget,
    );
    expect(find.text('Phone'), findsNothing);
    expect(
      tester.getSemantics(find.byKey(settingsAppearanceKey(ThemeMode.dark))),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(themeChoice.state, ThemeMode.dark, reason: 'dark until a tap, though the phone is light');

    await tester.tap(find.byKey(settingsAppearanceKey(ThemeMode.light)));
    await tester.pump();
    expect(themeChoice.state, ThemeMode.light);
    expect(
      tester.getSemantics(find.byKey(settingsAppearanceKey(ThemeMode.light))),
      isSemantics(isSelected: true, isButton: true),
    );
  });

  testWidgets('shows no heading, only the tab names the page, and the content status', (tester) async {
    await _pump(tester);

    expect(find.text('Settings'), findsNothing, reason: 'no heading, the tab names the page');
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('ffffffffffff'), findsOneWidget); // the first 12 characters, not all 64
    expect(find.text('f' * 64), findsNothing);
    expect(find.text('2026-11-01'), findsOneWidget);
    expect(find.text('Bundled with the app'), findsOneWidget);
    expect(find.text('Up to date'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Licences'), findsOneWidget);
  });

  testWidgets('the published day is the UTC day of the instant', (tester) async {
    // 2026-11-01T00:00:00.000Z is 2026-10-31 in every zone west of UTC; the UTC day is printed whatever the zone.
    await _pump(tester);

    expect(find.text('2026-11-01'), findsOneWidget);
    expect(find.text('2026-10-31'), findsNothing);
  });

  testWidgets('the published day of a late instant is its UTC day', (tester) async {
    // 2026-11-01T23:30:00.000Z is 2026-11-02 in every zone an hour or more east of UTC, so this case catches a local
    // day there, and the case above catches it west of UTC. A host on UTC (CI) cannot tell the two days apart.
    await _pump(tester, content: _contentBloc(index: _publishedAt(DateTime.utc(2026, 11, 1, 23, 30))));

    expect(find.text('2026-11-01'), findsOneWidget);
    expect(find.text('2026-11-02'), findsNothing);
  });

  testWidgets('a downloaded snapshot says so', (tester) async {
    await _pump(tester, content: _contentBloc(origin: ContentOrigin.downloaded));

    expect(find.text('Downloaded from the website'), findsOneWidget);
    expect(find.text('Bundled with the app'), findsNothing);
  });

  const refreshLines = <(RefreshStatus, String)>[
    (RefreshIdle(), 'Not checked since the app started'),
    (RefreshChecking(), 'Checking for updates'),
    (RefreshUpToDate(), 'Up to date'),
    (RefreshUpdated(), 'Updated to the latest content'),
    (RefreshNeedsAppUpdate(), 'Newer content needs a newer version of the app. Update the app to get it.'),
    (RefreshFailed(ContentErrorCode.network), 'The check for updates did not finish: no connection to the website.'),
    (
      RefreshFailed(ContentErrorCode.httpStatus),
      'The check for updates did not finish: the website answered with an error.',
    ),
    (
      RefreshFailed(ContentErrorCode.format),
      'The check for updates did not finish: the website sent content this version of the app cannot read.',
    ),
    (
      RefreshFailed(ContentErrorCode.checksum),
      'The check for updates did not finish: a downloaded file did not match its checksum.',
    ),
    (
      RefreshFailed(ContentErrorCode.storage),
      'The check for updates did not finish: the app could not write to its storage.',
    ),
    (
      RefreshFailed(ContentErrorCode.bundledIndexUnreadable),
      'The check for updates did not finish: the stored content could not be read.',
    ),
    (
      RefreshFailed(ContentErrorCode.missing),
      'The check for updates did not finish: the stored content could not be read.',
    ),
    (
      RefreshFailed(ContentErrorCode.corrupt),
      'The check for updates did not finish: the stored content could not be read.',
    ),
  ];
  for (final (refresh, line) in refreshLines) {
    testWidgets('the refresh status $refresh prints its line', (tester) async {
      await _pump(tester, content: _contentBloc(refresh: refresh));

      expect(find.text(line), findsOneWidget);
    });
  }

  testWidgets('Check for updates asks the content bloc', (tester) async {
    final content = _contentBloc();
    await _pump(tester, content: content);

    await tester.ensureVisible(find.text('Check for updates'));
    await tester.pump();
    await tester.tap(find.text('Check for updates'));
    await tester.pump();

    verify(() => content.add(any(that: isA<ContentRefreshRequested>()))).called(1);
  });

  testWidgets('Check for updates is off while checking', (tester) async {
    await _pump(tester, content: _contentBloc(refresh: const RefreshChecking()));

    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Check for updates'));
    expect(button.onPressed, isNull);
  });

  testWidgets('Check for updates is on otherwise', (tester) async {
    await _pump(tester, content: _contentBloc(refresh: const RefreshFailed(ContentErrorCode.network)));

    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Check for updates'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('the cacheDiscarded notice shows only when set', (tester) async {
    const notice =
        'The downloaded content could not be read, so the app removed it and shows the content that came with this '
        'version. Check for updates in Settings to download it again.';
    await _pump(tester);
    expect(find.text(notice), findsNothing);

    await _pump(tester, content: _contentBloc(notice: ContentNotice.cacheDiscarded));
    expect(find.text(notice), findsOneWidget);
  });

  testWidgets('a download after a discarded cache clears the notice', (tester) async {
    final repository = MockContentRepository();
    when(() => repository.open()).thenAnswer(
      (_) async => ContentOpening(
        index: catalogFixtureIndex(),
        origin: ContentOrigin.bundled,
        notice: ContentNotice.cacheDiscarded,
      ),
    );
    when(() => repository.refresh()).thenAnswer((_) async => ContentUpdated(index: catalogFixtureIndex()));
    // The real bloc runs outside the fake clock; the screen then shows the state it ended in.
    final updated = await tester.runAsync(() async {
      final bloc = ContentBloc(repository: repository)..add(const ContentStarted());
      final state = await bloc.stream.firstWhere((state) => state is ContentReady && state.refresh is RefreshUpdated);
      await bloc.close();
      return state;
    });
    final content = MockContentBloc();
    whenListen(content, const Stream<ContentState>.empty(), initialState: updated!);
    await _pump(tester, content: content);

    expect(find.text('Downloaded from the website'), findsOneWidget);
    expect(find.text('Updated to the latest content'), findsOneWidget);
    expect(find.byType(ContentNoticeBanner), findsNothing);
  });

  testWidgets('the content states other than ready draw nothing', (tester) async {
    final content = MockContentBloc();
    whenListen(content, const Stream<ContentState>.empty(), initialState: const ContentLoading());
    await _pump(tester, content: content);

    expect(find.text('Content'), findsNothing);
    expect(find.text('Check for updates'), findsNothing);
  });

  testWidgets('Licences opens the licence page under the app name', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.text('Licences'));
    await tester.pump();
    await tester.tap(find.text('Licences'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // the page spins while licences load

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('AI Engineering Bazaar'), findsWidgets);
  });

  testWidgets('the developer console button is there only with a callback', (tester) async {
    await _pump(tester);
    expect(find.text('Developer console'), findsNothing);

    final contexts = <BuildContext>[];
    await _pump(tester, openDevConsole: contexts.add);
    await tester.ensureVisible(find.text('Developer console'));
    await tester.pump();
    await tester.tap(find.text('Developer console'));
    await tester.pump();

    expect(contexts, hasLength(1));
  });

  testWidgets('text scale 2.0', (tester) async {
    await pumpAtTextScale(
      tester,
      bazaarTestApp(
        router: _router(openDevConsole: (_) {}),
        content: _contentBloc(notice: ContentNotice.cacheDiscarded),
      ),
      scale: 2.0,
    );

    expect(tester.takeException(), isNull);
    for (final target in [find.text('Check for updates'), find.text('Licences'), find.text('Developer console')]) {
      await tester.ensureVisible(target);
      await tester.pump();
      expectHittable(tester, target);
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(
      bazaarTestApp(
        platform: defaultTargetPlatform,
        router: _router(openDevConsole: (_) {}),
        content: _contentBloc(notice: ContentNotice.cacheDiscarded),
      ),
    );
    await tester.pump();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}

final class _TrackStore implements ITrackStore {
  Track? kept;

  @override
  Future<Track?> chosen() async => kept;

  @override
  Future<void> choose(Track track) async => kept = track;
}

/// A store that holds [icon] as the chosen app icon.
final class _KeptIcon implements IAppIconStore {
  const _KeptIcon(this.icon);

  final BazaarIcon icon;

  @override
  Future<BazaarIcon?> chosen() async => icon;

  @override
  Future<void> choose(BazaarIcon icon) async {}
}
