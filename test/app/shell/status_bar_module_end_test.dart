@Tags(['widget'])
library;

/// The iOS status bar tap over the reader in the app's router (plan 12.3): the owner found it did not go back to the top
/// at a module's end on the iPhone, though it did in the middle. A long synthetic module with wide tables, which scroll
/// sideways inside the page as a real module's do, and the pager at its end.
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/section_spine.dart';
import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/bazaar_app_harness.dart';
import '../../support/content_builders.dart';

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

Cell _cell(String text) => Cell(inlines: [TextInline(text: text)]);

/// A table wider than the screen, which scrolls sideways.
TableBlock _wide(int n) => TableBlock(
  number: '$n',
  title: 'Wide',
  rowHeaders: false,
  align: const [null, null, null, null, null, null],
  head: [for (var c = 0; c < 6; c++) _cell('A long column heading $c')],
  rows: [
    for (var r = 0; r < 3; r++) [for (var c = 0; c < 6; c++) _cell('A long cell of row $r, column $c')],
  ],
);

MockContentRepository _longModule() {
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer(
    (_) async => testDoc(
      title: 'First Module',
      body: [
        for (var i = 0; i < 90; i++) ...[
          _p('Paragraph $i of a long module, long enough to wrap a line or two on a phone.'),
          if (i % 30 == 29) _wide(i),
        ],
      ],
      next: testRef(),
    ),
  );
  return repository;
}

/// A tap on the iOS status bar, as the engine sends it, settled.
Future<void> _tapStatusBar(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.statusBar.name,
    SystemChannels.statusBar.codec.encodeMethodCall(const MethodCall('handleScrollToTop')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final end in [false, true]) {
    testWidgets(
      'a tap on the iOS status bar takes a module back to its top, ${end ? 'from its end' : 'from its middle'}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = const AppRouterFactory().create();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          bazaarTestApp(
            router: router,
            content: readyContentBloc(),
            record: readyRecordBloc(),
            repository: _longModule(),
            platform: TargetPlatform.iOS,
          ),
        );
        await tester.pumpAndSettle();
        router.push(BazaarPaths.module(Track.engineers, 'alpha/first'));
        await tester.pumpAndSettle();
        // The page's own scroll; the wide tables scroll sideways inside it.
        final page = find
            .byType(Scrollable)
            .evaluate()
            // The page's own, not the sections' beside it.
            .where((e) => e.findAncestorWidgetOfExactType<SectionSpine>() == null)
            .map((e) => ((e as StatefulElement).state as ScrollableState).position)
            .singleWhere((position) => position.axis == Axis.vertical);
        if (end) {
          page.jumpTo(page.maxScrollExtent - 300);
          await tester.pumpAndSettle();
          // The last stretch by hand, as a reader reaches the end: a fling past it, which bounces on iOS.
          await tester.flingFrom(const Offset(200, 400), const Offset(0, -1500), 3000);
          await tester.pumpAndSettle();
          expect(page.pixels, page.maxScrollExtent);
        } else {
          page.jumpTo(page.maxScrollExtent / 2);
          await tester.pumpAndSettle();
        }

        await _tapStatusBar(tester);

        expect(page.pixels, 0);
      },
    );
  }

  // The owner, on the phone (2026-11-17): back at the top by the status bar, the module's place was dropped, so the
  // continue band showed an older module instead.
  testWidgets('back at the top by the status bar, the module is kept at its top', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final places = ReadingPlacesBloc(store: MemoryReadingPlaceStore())..add(const ReadingPlacesStarted());
    addTearDown(places.close);
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(
        router: router,
        content: readyContentBloc(),
        record: readyRecordBloc(),
        repository: _longModule(),
        places: places,
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.pumpAndSettle();
    router.push(BazaarPaths.module(Track.engineers, 'alpha/first'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Paragraph 2 of a long module, long enough to wrap a line or two on a phone.'),
      const Offset(0, -1500),
    );
    await tester.pumpAndSettle();
    expect(places.state.of(Track.engineers, 'alpha/first'), isNotNull, reason: 'kept once scrolled by hand');

    await _tapStatusBar(tester);

    final place = places.state.of(Track.engineers, 'alpha/first');
    expect(place, isNotNull, reason: 'still the module being read, so the continue band offers it');
    expect(place!.share, 0);
    expect(place.offset, 0);
  });
}
