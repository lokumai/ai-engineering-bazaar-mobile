@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/section_spine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

void main() {
  // Review 12, C3: the sections beside the text did not scroll; at a larger size they overflowed the screen, and the
  // last ones could not be tapped, with no contents button in that layout.
  testWidgets('ten long sections beside the text at text scale 1.3 scroll, and the last one opens', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final names = [for (var i = 0; i < 10; i++) 'Section $i: how the parts of the system fit together'];
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer(
      (_) async => testDoc(
        title: 'First Module',
        toc: [for (final (i, n) in names.indexed) TocEntry(id: 's$i', text: n, depth: 2, mark: null)],
        body: [
          for (final (i, n) in names.indexed) ...[
            HeadingBlock(
              depth: 2,
              id: 's$i',
              mark: null,
              inlines: [TextInline(text: n)],
            ),
            ParagraphBlock(inlines: [TextInline(text: 'Text of $n.')], lead: false),
          ],
        ],
      ),
    );
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, repository: repository, platform: TargetPlatform.iOS));
    await tester.pumpAndSettle();
    router.push(BazaarPaths.module(Track.engineers, 'alpha/first'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final last = find.byKey(const ValueKey('section-spine-s9'));
    await tester.scrollUntilVisible(
      last,
      100,
      scrollable: find.descendant(of: find.byType(SectionSpine), matching: find.byType(Scrollable)),
    );
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
