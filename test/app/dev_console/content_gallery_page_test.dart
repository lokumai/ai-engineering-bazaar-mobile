@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/dev_console/content_gallery_page.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/logo_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/bazaar_app_harness.dart';
import '../../support/content_builders.dart';

const _sample = 'Sphinx of black quartz, judge my vow 0123456789';
const _firstDoc = 'api/v1/modules/alpha/first/en.json';
const _secondDoc = 'api/v1/modules/alpha/second/en.json';

const _diagram = DiagramBlock(
  number: '1.1',
  title: 'Flow',
  svgLight: 'api/v1/diagrams/l.svg',
  svgDark: 'api/v1/diagrams/d.svg',
);
const _webp = ImageBlock(
  number: '1.2',
  title: null,
  note: null,
  src: 'course-images/alpha/b.webp',
  alt: 'An animation',
  width: 1280,
  height: 720,
);
const _png = ImageBlock(
  number: '1.3',
  title: null,
  note: null,
  src: 'course-images/alpha/c.png',
  alt: 'A still',
  width: 10,
  height: 10,
);

void main() {
  late MockContentRepository repository;
  setUpAll(() => S.load(const Locale('en')));

  setUp(() {
    repository = MockContentRepository();
    when(
      () => repository.readObject(any()),
    ).thenAnswer((invocation) async => throw ContentMissingException(invocation.positionalArguments.first as String));
    when(() => repository.readModuleDoc(_firstDoc)).thenAnswer(
      (_) async => testDoc(
        body: const [
          _diagram,
          _webp,
          // The same diagram again, and a figure that is not WebP: neither is drawn a second time.
          QuoteBlock(label: null, blocks: [_diagram, _png]),
        ],
      ),
    );
    when(() => repository.readModuleDoc(_secondDoc))
        .thenAnswer((_) async => throw const ContentMissingException(_secondDoc));
  });

  Future<void> pumpGallery(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 24000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final index = testIndex(
      modules: [
        testModule(),
        testModule(key: 'alpha/second', number: 2),
      ],
      images: {'course-images/alpha/logos/a.svg': 'b' * 64, 'course-images/alpha/b.webp': 'c' * 64},
    );
    await pumpInTheme(
      tester,
      BlocProvider<ContentBloc>.value(value: readyContentBloc(index), child: const ContentGalleryPage()),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);
  }

  testWidgets('draws every diagram in both variants, every logo in both themes, the WebP figures and the fonts', (
    tester,
  ) async {
    await pumpGallery(tester);

    final diagrams = tester.widgetList<DiagramView>(find.byType(DiagramView)).toList();
    expect(diagrams.map((view) => view.variant), [DiagramVariant.light, DiagramVariant.dark]);
    final logos = find.byType(LogoView);
    expect(logos, findsNWidgets(2));
    expect([for (final element in logos.evaluate()) Theme.of(element).brightness], [Brightness.light, Brightness.dark]);
    expect(tester.widgetList<FigureImage>(find.byType(FigureImage)).map((figure) => figure.block.src), [_webp.src]);
    expect(find.text(_sample), findsNWidgets(4));
    expect(find.text('api/v1/diagrams/l.svg'), findsNWidgets(2));
    expect(find.text('course-images/alpha/logos/a.svg'), findsOneWidget);
  });

  testWidgets('a document that cannot be read shows its path and the others still draw', (tester) async {
    await pumpGallery(tester);

    expect(find.descendant(of: find.byType(ContentUnreadable), matching: find.text(_secondDoc)), findsOneWidget);
    expect(find.byType(DiagramView), findsNWidgets(2));
  });

  testWidgets('an error other than an unreadable document is not swallowed', (tester) async {
    when(() => repository.readModuleDoc(_secondDoc)).thenAnswer((_) async => throw StateError('x'));
    await pumpGallery(tester);

    expect(tester.takeException(), isA<StateError>());
  });
}
