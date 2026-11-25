@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
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

Future<void> _open(WidgetTester tester, {Object? extra}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: _sections(), platform: TargetPlatform.iOS));
  await tester.pumpAndSettle();
  router.push(BazaarPaths.module(Track.engineers, 'alpha/first'), extra: extra);
  await tester.pumpAndSettle();
}

void main() {
  // Review 12, C2: a page that kept no place, as a glance from the day's card, had none to find after a new reading
  // size or a turn of the screen, so the same pixels showed other words.
  testWidgets('a module opened for a glance keeps its words in view through a text size change', (tester) async {
    await _open(tester, extra: const ReaderTarget(glance: true));
    await tester.drag(find.byWidgetPredicate((w) => w is SingleChildScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final before = _topParagraph(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.45;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    final after = _topParagraph(tester);
    expect(after, before);
  });
}

String _topParagraph(WidgetTester tester) {
  final view = find.byWidgetPredicate((w) => w is SingleChildScrollView).first;
  final top = tester.getTopLeft(view).dy;
  String? first;
  var firstTop = double.infinity;
  for (final name in const ['Section one', 'Section two', 'Section three']) {
    for (var i = 0; i < 25; i++) {
      final text = 'Paragraph $i of $name,';
      final found = find.textContaining(text, findRichText: true);
      if (found.evaluate().isEmpty) continue;
      final rect = tester.getRect(found.first);
      if (rect.bottom > top + 1 && rect.top < firstTop) {
        first = text;
        firstTop = rect.top;
      }
    }
  }
  return first!;
}
