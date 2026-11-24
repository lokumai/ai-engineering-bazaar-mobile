@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

MockContentRepository _sections() {
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer(
    (_) async => testDoc(
      title: 'First Module',
      toc: const [
        TocEntry(id: 'one', text: 'Section one', depth: 2, mark: null),
        TocEntry(id: 'two', text: 'Section two', depth: 2, mark: null),
        TocEntry(id: 'three', text: 'Section three', depth: 2, mark: null),
      ],
      body: [
        for (final (id, name) in const [
          ('one', 'Section one'),
          ('two', 'Section two'),
          ('three', 'Section three'),
        ]) ...[
          HeadingBlock(
            depth: 2,
            id: id,
            mark: null,
            inlines: [TextInline(text: name)],
          ),
          for (var i = 0; i < 25; i++)
            ParagraphBlock(inlines: [TextInline(text: 'Paragraph $i of $name, long enough to wrap.')], lead: false),
        ],
      ],
    ),
  );
  return repository;
}

ScrollPosition _vertical(WidgetTester tester) => find
    .byType(Scrollable)
    .evaluate()
    .map((e) => ((e as StatefulElement).state as ScrollableState).position)
    .singleWhere((position) => position.axis == Axis.vertical);

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: _sections(), platform: TargetPlatform.iOS));
  await tester.pumpAndSettle();
  router.push(BazaarPaths.module(Track.engineers, 'alpha/first'));
  await tester.pumpAndSettle();
}

/// Review 10, finding 1: the text was built anew as the sections came in or went beside it, so a tablet turned sent the
/// module back to its top.
void main() {
  testWidgets('iPad 11 portrait to landscape (834 -> 1194): the place is kept', (tester) async {
    await _open(tester, const Size(834, 1194));
    _vertical(tester).jumpTo(900);
    await tester.pumpAndSettle();
    expect(_vertical(tester).pixels, 900);

    tester.view.physicalSize = const Size(1194, 834);
    await tester.pumpAndSettle();
    expect(_vertical(tester).pixels, 900, reason: 'the text column is as wide in both layouts');
  });

  testWidgets('landscape to portrait (1194 -> 834): the place is kept', (tester) async {
    await _open(tester, const Size(1194, 834));
    _vertical(tester).jumpTo(900);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(834, 1194);
    await tester.pumpAndSettle();
    expect(_vertical(tester).pixels, 900);
  });

  testWidgets('a small tablet turned (600 -> 960): the place is kept', (tester) async {
    await _open(tester, const Size(600, 960));
    _vertical(tester).jumpTo(900);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(960, 600);
    await tester.pumpAndSettle();
    expect(_vertical(tester).pixels, greaterThan(0), reason: 'a narrower column, so not the same pixels');
  });
}
