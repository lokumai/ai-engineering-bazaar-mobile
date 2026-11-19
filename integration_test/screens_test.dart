@Timeout(Duration(minutes: 15))
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'support/device_app.dart';

/// A tour of the app's screens for comparing Android and iOS side by side. At each stop the test prints
/// `BAZAAR_SHOT <name>` and holds the screen still for a few seconds, so a script on the host takes a native screenshot
/// (status bar, navigation bar and the phone's own sheets included): `tool/parity_shots.sh`.
///
/// It asserts nothing about the screens; it only fails when a page throws.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const hold = Duration(milliseconds: 3500);

  // Pumps for [time] without waiting for animations to end (the robot and the film keep moving).
  Future<void> settleFor(WidgetTester tester, Duration time) async {
    final end = DateTime.now().add(time);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    // The robot and the film never settle, so the screen is pumped for a while instead.
    await settleFor(tester, const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull, reason: name);
    // ignore: avoid_print
    print('BAZAAR_SHOT $name');
    await tester.runAsync(() => Future<void>.delayed(hold));
  }

  Future<void> open(WidgetTester tester, String path) async {
    goTo(tester, path);
    await settleFor(tester, const Duration(milliseconds: 1500));
  }

  Future<void> scrollBy(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await settleFor(tester, const Duration(milliseconds: 800));
  }

  testWidgets('every screen, for the Android and iOS comparison', (tester) async {
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('bazaar_shots_')))!;
    addTearDown(() => dir.delete(recursive: true));
    await pumpDeviceApp(tester, directory: dir);
    final content = await pumpUntil<ContentBloc, ContentState>(
      tester,
      (s) => s is ContentReady && s.refresh is! RefreshChecking && s.refresh is! RefreshIdle,
    ) as ContentReady;
    await pumpUntilShown(tester);
    await settleFor(tester, const Duration(seconds: 2));

    final index = content.index;
    final level = index.levels.first;
    final written = index.modules.firstWhere((m) => m.tracks[Track.engineers]?.drawn ?? false);

    Future<void> openModule(Track track, String key) async {
      final path = BazaarPaths.module(track, key);
      goTo(tester, path);
      await pumpUntil<ModuleReaderBloc, ReaderState>(tester, (s) => currentPath(tester) == path && s is! ReaderLoading);
      await settleFor(tester, const Duration(milliseconds: 1500));
    }

    Future<void> pages(String scheme) async {
      await open(tester, BazaarPaths.home);
      await shot(tester, '$scheme-01-home');
      await scrollBy(tester, 500);
      await shot(tester, '$scheme-02-home-scrolled');

      await open(tester, BazaarPaths.catalogEngineers);
      await shot(tester, '$scheme-03-catalog');
      // The track switch follows the current track, so the reader's choice moves to For Everyone for this shot.
      blocOf<TrackCubit>(tester).select(Track.everyone);
      await open(tester, BazaarPaths.catalogEveryone);
      await shot(tester, '$scheme-04-catalog-everyone');
      blocOf<TrackCubit>(tester).select(Track.engineers);
      await open(tester, BazaarPaths.level(Track.engineers, level.slug));
      await shot(tester, '$scheme-05-level');

      await openModule(Track.engineers, written.key);
      await shot(tester, '$scheme-06-module-top');
      await scrollBy(tester, 900);
      await shot(tester, '$scheme-07-module-text');

      await open(tester, BazaarPaths.practice);
      await shot(tester, '$scheme-08-practice');
      await open(tester, BazaarPaths.practiceEndless);
      await shot(tester, '$scheme-09-practice-session');
      await open(tester, BazaarPaths.practiceGlossary);
      await shot(tester, '$scheme-10-glossary');

      await open(tester, BazaarPaths.caravan);
      await shot(tester, '$scheme-11-caravan');

      await open(tester, BazaarPaths.settings);
      await shot(tester, '$scheme-12-settings-top');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-send-to-website')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await settleFor(tester, const Duration(milliseconds: 600));
      await shot(tester, '$scheme-13-settings-website');
      await scrollBy(tester, 5000);
      await shot(tester, '$scheme-14-settings-bottom');

      await open(tester, '/settings/reading');
      await shot(tester, '$scheme-15-reading');
      await open(tester, '/settings/robot');
      await shot(tester, '$scheme-16-robot');
      await open(tester, '/settings/guide');
      await shot(tester, '$scheme-17-guide');
      await open(tester, '/settings/privacy');
      await shot(tester, '$scheme-18-privacy');

      goTo(tester, BazaarPaths.home);
      await settleFor(tester, const Duration(milliseconds: 800));
      // A progress link with invented modules: nothing is added, the page only shows what it carries.
      GoRouter.of(tester.element(find.byType(Navigator).first)).push(
        BazaarPaths.transfer,
        extra: 'fczBCoMwEATQf5nzirtb8JBfkT2kJqKgrWgRavDfTUV69DjMm0lY4YQQ4RL8MHW-bPt5-cDVGNdNxo1nELw8tXkEUM2kZnTRJTbvV_jZbHIpZjvhe__FLUcOnPmpz7myVoVIwZLBPyhsPwA',
      );
      await settleFor(tester, const Duration(milliseconds: 1500));
      await shot(tester, '$scheme-19-transfer');
    }

    await pages('light');

    blocOf<ThemeChoiceCubit>(tester).choose(ThemeMode.dark);
    await settleFor(tester, const Duration(seconds: 1));
    await pages('dark');

    // Persian, right to left, light: the pages where the direction shows most.
    blocOf<ThemeChoiceCubit>(tester).choose(ThemeMode.light);
    await blocOf<LanguageCubit>(tester).choose('fa');
    await settleFor(tester, const Duration(seconds: 1));
    await open(tester, BazaarPaths.home);
    await shot(tester, 'fa-01-home');
    await open(tester, BazaarPaths.catalogEngineers);
    await shot(tester, 'fa-03-catalog');
    await openModule(Track.engineers, written.key);
    await shot(tester, 'fa-06-module-top');
    await open(tester, BazaarPaths.settings);
    await shot(tester, 'fa-12-settings-top');
    await blocOf<LanguageCubit>(tester).choose('en');
    await settleFor(tester, const Duration(seconds: 1));

    // The story of the Bazaar, a film over the whole screen.
    await open(tester, '/settings/about');
    await settleFor(tester, const Duration(seconds: 3));
    print('BAZAAR_SHOT light-20-about'); // ignore: avoid_print
    await tester.runAsync(() => Future<void>.delayed(hold));

    // Last, the phone's own share sheet over a module: nothing after it, since the test cannot close it.
    await openModule(Track.engineers, written.key);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reader-share')),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await settleFor(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('reader-share')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    print('BAZAAR_SHOT light-21-share-sheet'); // ignore: avoid_print
    await tester.runAsync(() => Future<void>.delayed(hold));
  });
}
