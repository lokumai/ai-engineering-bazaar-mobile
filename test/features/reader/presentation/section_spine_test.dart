@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/section_spine.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/readable_width.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

/// A module of three sections, each long enough to fill a tablet's screen.
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

Future<ScrollPosition> _pumpModule(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = const AppRouterFactory().create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: _sections(), platform: TargetPlatform.iOS));
  await tester.pumpAndSettle();
  router.push(BazaarPaths.module(Track.engineers, 'alpha/first'));
  await tester.pumpAndSettle();
  return find
      .byType(Scrollable)
      .evaluate()
      .map((e) => ((e as StatefulElement).state as ScrollableState).position)
      .singleWhere((position) => position.axis == Axis.vertical);
}

/// The width of the module's text column.
double _textWidth(WidgetTester tester) => tester.getSize(find.byType(SingleChildScrollView).first).width;

/// Whether [id]'s row is drawn as the section in view.
bool _inView(WidgetTester tester, String id) =>
    tester
        .widget<Text>(find.descendant(of: find.byKey(SectionSpine.rowKey(id)), matching: find.byType(Text)))
        .style
        ?.fontWeight ==
    FontWeight.w600;

void main() {
  testWidgets('an iPad in landscape: the sections beside the text, which keeps its measure (plan 12.10)', (
    tester,
  ) async {
    final page = await _pumpModule(tester, const Size(1366, 1024));

    expect(find.byType(SectionSpine), findsOneWidget);
    expect(_textWidth(tester), ReadableWidth.text);
    expect(find.text('Contents'), findsNothing, reason: 'the sections replace the contents button');
    expect(
      tester.getCenter(find.byType(SectionSpine)).dx,
      lessThan(tester.getCenter(find.byType(SingleChildScrollView).first).dx),
      reason: 'at the start',
    );

    // A tap on a section scrolls to it, and it is the one in view.
    await tester.tap(find.byKey(SectionSpine.rowKey('two')));
    await tester.pumpAndSettle();
    expect(page.pixels, greaterThan(0));
    expect(_inView(tester, 'two'), isTrue);
    expect(_inView(tester, 'one'), isFalse);

    // The status bar's tap scrolls the text, not the sections.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.statusBar.name,
      SystemChannels.statusBar.codec.encodeMethodCall(const MethodCall('handleScrollToTop')),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(page.pixels, 0);
  });

  testWidgets('an iPad in portrait and a phone: one column, at the reading measure at most', (tester) async {
    for (final size in const [Size(834, 1194), Size(390, 844)]) {
      await _pumpModule(tester, size);
      expect(find.byType(SectionSpine), findsNothing, reason: '$size');
      expect(_textWidth(tester), lessThanOrEqualTo(ReadableWidth.text), reason: '$size');
      expect(find.text('Contents'), findsOneWidget, reason: '$size');
    }
  });
}
