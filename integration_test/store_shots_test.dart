@Timeout(Duration(minutes: 20))
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_view.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/device_app.dart';

/// The store's screenshots (plan 21.7): a few screens in each language, with some progress and an Apprentice that has
/// read a few modules, so the pages are not empty. As `screens_test.dart`, it prints `BAZAAR_SHOT <name>` and holds
/// the screen still while `tool/parity_shots.sh` takes a native screenshot:
///
/// ```shell
/// tool/parity_shots.sh ios <simulator udid> <out dir> integration_test/store_shots_test.dart
/// ```
///
/// The languages are `--dart-define=STORE_LANGUAGES=en,tr` (default en,tr,fa: Google Play takes Persian, the App Store
/// has no Persian listing). It asserts nothing about the screens; it only fails when a page throws.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A debug build draws the DEBUG ribbon in a corner; a store screenshot must not.
  WidgetsApp.debugAllowBannerOverride = false;

  const languages = String.fromEnvironment('STORE_LANGUAGES', defaultValue: 'en,tr,fa');
  const hold = Duration(milliseconds: 3500);

  Future<void> settleFor(WidgetTester tester, Duration time) async {
    final end = DateTime.now().add(time);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settleFor(tester, const Duration(milliseconds: 800));
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

  // The next figure (a diagram or a picture) is brought up whole, with its caption, over the bars: a shorter phone than the iPhone leaves
  // it under the fold. The page moves by exactly what is needed (a drag would fling past it); a figure not built yet
  // is reached by a few short moves.
  Future<void> showFigure(WidgetTester tester) async {
    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final limit = screen - 150;
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    Future<void> moveBy(double dy) async {
      position.jumpTo((position.pixels + dy).clamp(position.minScrollExtent, position.maxScrollExtent));
      await settleFor(tester, const Duration(milliseconds: 800));
    }

    for (var attempt = 0; attempt < 4; attempt++) {
      for (final element in find.byType(FigureView).evaluate()) {
        final rect = tester.getRect(find.byElementPredicate((e) => e == element));
        if (rect.top < 0) continue;
        final below = rect.bottom + 8 - limit;
        if (below > 0) await moveBy(below);
        return;
      }
      await moveBy(200);
    }
  }

  testWidgets('the store screenshots', (tester) async {
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('bazaar_store_')))!;
    addTearDown(() => dir.delete(recursive: true));
    await pumpDeviceApp(tester, directory: dir);
    final content = await pumpUntil<ContentBloc, ContentState>(
      tester,
      (s) => s is ContentReady && s.refresh is! RefreshChecking && s.refresh is! RefreshIdle,
    ) as ContentReady;
    await pumpUntilShown(tester);
    await settleFor(tester, const Duration(seconds: 2));

    final index = content.index;
    final written = index.modules.where((m) => m.tracks[Track.engineers]?.drawn ?? false).toList();

    // Some progress: the first five written modules completed, the sixth the one Home goes on with.
    final done = written.take(5).toList();
    for (final module in done) {
      blocOf<RecordBloc>(tester).add(
        CompletionToggled(
          key: module.key,
          track: Track.engineers,
          revision: module.tracks[Track.engineers]?.revision?.hash,
        ),
      );
    }
    await settleFor(tester, const Duration(seconds: 1));

    // The Apprentice reads the finished modules, one at a time as the reader gives them, so it has a level and words
    // of its own and no module waits on its button. A slow device may not finish one; the shots go on with what it read.
    for (final module in done) {
      blocOf<PocketModelBloc>(tester).add(PocketModelModuleRead(module.key));
      final reading = Stopwatch()..start();
      while (reading.elapsed < const Duration(seconds: 60)) {
        await tester.pump(const Duration(milliseconds: 200));
        final state = blocOf<PocketModelBloc>(tester).state;
        if (state is PocketModelReady && state.model.hasRead(module.key)) break;
      }
    }

    final next = written[5];
    final pictured = written.firstWhere((m) => m.key.contains('rag'), orElse: () => written.first);

    Future<void> openModule(String key) async {
      final path = BazaarPaths.module(Track.engineers, key);
      goTo(tester, path);
      await pumpUntil<ModuleReaderBloc, ReaderState>(tester, (s) => currentPath(tester) == path && s is! ReaderLoading);
      await settleFor(tester, const Duration(milliseconds: 1500));
    }

    // Opening the next module once makes it the one Home goes on with.
    await openModule(next.key);
    await scrollBy(tester, 600);

    // Six screens, all in the light theme (the owner, 2026-11-20).
    await blocOf<ThemeChoiceCubit>(tester).choose(ThemeMode.light);
    for (final language in languages.split(',')) {
      await blocOf<LanguageCubit>(tester).choose(language);
      await settleFor(tester, const Duration(seconds: 1));

      await open(tester, BazaarPaths.home);
      await shot(tester, '$language-01-home');

      await openModule(pictured.key);
      await scrollBy(tester, 1400);
      await showFigure(tester);
      await shot(tester, '$language-02-module-text');

      await open(tester, BazaarPaths.catalogEngineers);
      await shot(tester, '$language-03-catalog');

      await open(tester, BazaarPaths.practice);
      await shot(tester, '$language-04-practice');

      await open(tester, BazaarPaths.caravan);
      await settleFor(tester, const Duration(seconds: 2));
      await shot(tester, '$language-05-caravan');

      await open(tester, '/settings/robot');
      await shot(tester, '$language-06-apprentice');
    }

    await blocOf<LanguageCubit>(tester).choose('en');
    await blocOf<ThemeChoiceCubit>(tester).choose(ThemeMode.light);
    await settleFor(tester, const Duration(seconds: 1));
  });
}
