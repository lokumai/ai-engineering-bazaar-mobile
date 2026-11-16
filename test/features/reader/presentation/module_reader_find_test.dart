@Tags(['widget'])
library;

// The words searched in the catalog, stepped through in the module (plan 7.1): where the steps start and go once the
// page opened at a reading place or the reader scrolled, their order in a right-to-left table, the title's marks and
// reduced motion. The bar's basics are in module_reader_page_test.dart.

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' hide Block;

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

final first = testModule();
final index = testIndex(modules: [first]);

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

/// Enough paragraphs to push what follows below an 844 px screen.
List<Block> _filler(String tag) => [for (var i = 0; i < 40; i++) _p('Filler $tag $i of the module body.')];

const _sectionOne = HeadingBlock(
  depth: 2,
  id: 'one',
  mark: null,
  inlines: [TextInline(text: 'Section one')],
);
const _toc = [TocEntry(id: 'one', text: 'Section one', depth: 2, mark: null)];

void main() {
  late MockModuleReaderBloc readerBloc;
  setUp(() => readerBloc = MockModuleReaderBloc());

  void doc(List<Block> body, {String title = 'First'}) => whenListen(
    readerBloc,
    const Stream<ReaderState>.empty(),
    initialState: ReaderWritten(
      doc: testDoc(title: title, toc: _toc, body: body),
      entry: first,
      moduleCount: 1,
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
    String? fragment,
    String query = 'agent',
    ReadingPlace? place,
    bool reducedMotion = false,
    String lang = 'en',
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/reader',
      routes: [
        GoRoute(
          path: '/reader',
          builder: (context, _) {
            final view = BlocProvider<ModuleReaderBloc>.value(
              value: readerBloc,
              child: ModuleReaderView(fragment: fragment, query: query, place: place),
            );
            if (!reducedMotion) return view;
            return MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: view);
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(
        router: router,
        content: readyContentBloc(index),
        language: LanguageCubit(initial: lang),
        locale: Locale(lang),
      ),
    );
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text, findRichText: true)).dy;
  bool onScreen(WidgetTester tester, String text) {
    final y = top(tester, text);
    return y >= 0 && y < 844;
  }

  String bar(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((t) => RegExp(r'^\d+ / \d+$').hasMatch(t), orElse: () => '(no bar)');

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
  }

  final at = DateTime.utc(2026, 11, 16, 9);

  testWidgets('opened where the module was left, the bar starts at the mark on screen, not at one far above', (
    tester,
  ) async {
    doc([_p('An agent at the top.'), ..._filler('a'), _sectionOne, _p('The agent where I left off.'), ..._filler('b')]);
    // A search hit with no section (the module card, Open module): the module opens where it was left.
    await pump(
      tester,
      place: ReadingPlace(heading: 'one', offset: 0, share: 0.5, at: at),
    );

    expect(onScreen(tester, 'The agent where I left off.'), isTrue, reason: 'the page opened at the place');
    expect(bar(tester), '2 / 2', reason: 'the current mark should be the one on screen');
  });

  testWidgets('a step is kept when a picture loads, rather than the page going back to where the module was left', (
    tester,
  ) async {
    doc([
      ..._filler('a'),
      _sectionOne,
      _p('The agent where I left off.'),
      ..._filler('b'),
      _p('A later agent far below.'),
      ..._filler('c'),
    ]);
    await pump(
      tester,
      place: ReadingPlace(heading: 'one', offset: 0, share: 0.5, at: at),
    );

    await next(tester);
    expect(onScreen(tester, 'A later agent far below.'), isTrue, reason: 'the step brought the far mark into view');

    // A picture above loads: the page's length changes, as the scroll view reports with a metrics notification.
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    ScrollMetricsNotification(
      metrics: scrollable.position.copyWith(),
      context: scrollable.context,
    ).dispatch(scrollable.context);
    await tester.pumpAndSettle();

    expect(
      top(tester, 'A later agent far below.'),
      inInclusiveRange(0, 844),
      reason: 'the page must not jump back to the reading place after the reader stepped',
    );
    expect(top(tester, 'Section one'), lessThan(0), reason: 'it jumped back to the reading place');
  });

  testWidgets('after the reader scrolls on past a mark, Next goes to the next mark on or below the page, not back up', (
    tester,
  ) async {
    doc([
      _sectionOne,
      _p('The agent of the section.'),
      ..._filler('a'),
      _p('A second agent.'),
      ..._filler('b'),
      _p('A third agent.'),
      ..._filler('c'),
    ]);
    await pump(tester, fragment: 'one');
    expect(find.text('1 / 3'), findsOneWidget);

    // The reader reads on: scrolls by hand until the third mark is on screen, past the second.
    await tester.scrollUntilVisible(
      find.text('A third agent.', findRichText: true),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(top(tester, 'A second agent.'), lessThan(0), reason: 'the second mark is above the screen now');

    await next(tester);

    expect(bar(tester), '3 / 3', reason: 'Next from where the reader is, not from the old mark');
    expect(top(tester, 'A third agent.'), inInclusiveRange(0, 844), reason: 'the page went back up');
  });

  testWidgets('after the reader scrolls on past a mark, Previous goes to the last mark above the page', (tester) async {
    doc([
      _sectionOne,
      _p('The agent of the section.'),
      ..._filler('a'),
      _p('A second agent.'),
      ..._filler('b'),
      _p('A third agent.'),
      ..._filler('c'),
    ]);
    await pump(tester, fragment: 'one');

    await tester.scrollUntilVisible(
      find.text('A third agent.', findRichText: true),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous match'));
    await tester.pumpAndSettle();

    expect(bar(tester), '2 / 3');
    expect(top(tester, 'A second agent.'), inInclusiveRange(0, 844));
  });

  testWidgets('in Persian a table row is stepped right to left, as it is read', (tester) async {
    doc([
      const TableBlock(
        number: '1',
        title: null,
        rowHeaders: false,
        align: [null, null],
        head: [
          Cell(inlines: [TextInline(text: 'agent one')]),
          Cell(inlines: [TextInline(text: 'agent two')]),
        ],
        rows: [],
      ),
    ]);
    await pump(tester, lang: 'fa');

    // The first column stands on the right in Persian: it is the first mark.
    expect(
      tester.getTopLeft(find.text('agent one', findRichText: true)).dx,
      greaterThan(tester.getTopLeft(find.text('agent two', findRichText: true)).dx),
    );
    expect(_currentMarkText(tester), 'agent', reason: 'sanity: a mark is current');
    expect(_currentCell(tester), 'agent one', reason: 'the first mark is the first column, on the right');
  });

  testWidgets('a module found by its title has its title marked', (tester) async {
    doc([_p('Nothing about it here.')], title: 'The agent module');
    await pump(tester);

    expect(bar(tester), '1 / 1', reason: 'the catalog found the module by the word in its title');
  });

  testWidgets('the title keeps the title colour as marked text', (tester) async {
    doc([_p('Nothing here.')], title: 'The agent module');
    await pump(tester);
    final colors = tester.element(find.byType(Scaffold).first).bazaarColors;

    final title = tester.widget<RichText>(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == 'The agent module'),
    );
    // Text.rich wraps the text's own span in the ambient style: the title's colour is on the span inside.
    final own = (title.text as TextSpan).children!.single;
    expect(own.style?.color, colors.onSurfaceTitle);
  });

  testWidgets('under reduced motion a step moves the page at once', (tester) async {
    doc([_p('Top.'), ..._filler('a'), _p('A far agent.'), ..._filler('b')]);
    await pump(tester, reducedMotion: true);

    await tester.tap(find.byTooltip('Next match'));
    await tester.pump(); // one frame, no animation time
    await tester.pump();

    expect(top(tester, 'A far agent.'), inInclusiveRange(0, 844), reason: 'no animation under reduced motion');
  });
}

/// The text of the current (strongly marked) mark on the page.
String? _currentMarkText(WidgetTester tester) {
  String? found;
  for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
    text.text.visitChildren((span) {
      if (span is TextSpan && span.style?.color != null && span.style?.background != null) found = span.text;
      return found == null;
    });
  }
  return found;
}

/// The whole text of the piece holding the current mark.
String? _currentCell(WidgetTester tester) {
  for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
    var current = false;
    text.text.visitChildren((span) {
      if (span is TextSpan && span.style?.color != null && span.style?.background != null) current = true;
      return !current;
    });
    if (current) return text.text.toPlainText();
  }
  return null;
}
