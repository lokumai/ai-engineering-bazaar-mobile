@Tags(['widget'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_full_screen.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/content_builders.dart';

const _diagrams = 'test/fixtures/content/src/api/v1/diagrams';

const block = DiagramBlock(
  number: '1.1',
  title: 'Flow',
  svgLight: 'api/v1/diagrams/l.svg',
  svgDark: 'api/v1/diagrams/d.svg',
);

const themes = DiagramThemes(
  light: DiagramTheme(theme: 'default', backgroundArgb: 0xFFFFFFFF),
  dark: DiagramTheme(theme: 'dark', backgroundArgb: 0xFF333333),
);

void main() {
  late MockContentRepository repository;
  late Uint8List darkBytes;
  setUpAll(() => S.load(const Locale('en')));

  setUp(() {
    repository = MockContentRepository();
    final light = File('$_diagrams/77235fba878b47f1d72f180d8babf2c4.svg').readAsBytesSync();
    darkBytes = File('$_diagrams/9bb8502b0371cba0d2e5b7e98362455e.svg').readAsBytesSync();
    when(() => repository.readObject('api/v1/diagrams/l.svg')).thenAnswer((_) async => Uint8List.fromList(light));
    when(() => repository.readObject('api/v1/diagrams/d.svg')).thenAnswer((_) async => darkBytes);
  });

  BoxDecoration frameDecoration(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byKey(const Key('diagram-frame'))).decoration as BoxDecoration;

  testWidgets('a light theme draws svgLight on the white ground with the light frame edge', (tester) async {
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);

    verify(() => repository.readObject('api/v1/diagrams/l.svg')).called(1);
    verifyNever(() => repository.readObject('api/v1/diagrams/d.svg'));
    final decoration = frameDecoration(tester);
    expect(decoration.color, const Color(0xFFFFFFFF));
    expect((decoration.border! as Border).top.color, DiagramFrameInk.of(DiagramVariant.light).edge);
    expect(find.byKey(DiagramView.expandKey), findsOneWidget, reason: 'the mark that it opens full screen');
    expect(find.byType(InteractiveViewer), findsNothing, reason: 'the page scrolls over it; it zooms full screen');
    expect(find.bySemanticsLabel('FIG. 1.1 · Flow'), findsOneWidget);
  });

  testWidgets('a tap opens the diagram full screen, to zoom, and the close button comes back', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('FIG. 1.1 · Flow')),
      matchesSemantics(
        isImage: true,
        isButton: true,
        hasTapAction: true,
        label: 'FIG. 1.1 · Flow',
        hint: 'Open the diagram full screen',
      ),
    );

    await tester.tap(find.byKey(const Key('diagram-frame')));
    await tester.pumpAndSettle();
    expect(find.byType(DiagramFullScreen), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor, const Color(0xFFFFFFFF));

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(DiagramFullScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets('a dark theme still draws svgLight on the white ground, as photos stay as they are', (tester) async {
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.dark,
      repository: repository,
    );
    await settleContent(tester);

    verify(() => repository.readObject('api/v1/diagrams/l.svg')).called(1);
    verifyNever(() => repository.readObject('api/v1/diagrams/d.svg'));
    final decoration = frameDecoration(tester);
    expect(decoration.color, const Color(0xFFFFFFFF));
    expect((decoration.border! as Border).top.color, DiagramFrameInk.of(DiagramVariant.light).edge);
    expect(find.byKey(DiagramView.expandKey), findsOneWidget);
  });

  testWidgets('variant overrides the brightness', (tester) async {
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes, variant: DiagramVariant.dark),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);

    verify(() => repository.readObject('api/v1/diagrams/d.svg')).called(1);
    verifyNever(() => repository.readObject('api/v1/diagrams/l.svg'));
    expect(frameDecoration(tester).color, const Color(0xFF333333));
  });

  testWidgets('a vertical drag over a diagram scrolls the page', (tester) async {
    await pumpInTheme(
      tester,
      ListView(
        children: const [
          DiagramView(block: block, themes: themes),
          SizedBox(key: Key('after'), height: 2000),
        ],
      ),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);
    final before = tester.getTopLeft(find.byKey(const Key('after'))).dy;

    await tester.drag(find.byType(SvgPicture), const Offset(0, -300));
    await tester.pumpAndSettle();

    // The list's drag wins past the touch slop, so the first kDragSlopDefault pixels may not be scrolled.
    expect(tester.getTopLeft(find.byKey(const Key('after'))).dy, closeTo(before - 300, kDragSlopDefault));
    expect(find.byType(DiagramFullScreen), findsNothing, reason: 'a drag is not a tap');
  });

  testWidgets('a missing diagram shows the unreadable state', (tester) async {
    when(() => repository.readObject(any())).thenThrow(const ContentMissingException('api/v1/diagrams/l.svg'));
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);

    expect(find.text(S.current.content_unreadable), findsOneWidget);
    expect(find.byKey(DiagramView.expandKey), findsNothing, reason: 'nothing to open');
  });

  testWidgets('a corrupt diagram shows the unreadable state', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) async => throw const ContentCorruptException('x'));
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);

    expect(find.text(S.current.content_unreadable), findsOneWidget);
  });

  testWidgets('a variant change while the light read is pending draws the dark variant and drops the light bytes', (
    tester,
  ) async {
    final lightRead = Completer<Uint8List>();
    final lightBytes = Uint8List.fromList(File('$_diagrams/77235fba878b47f1d72f180d8babf2c4.svg').readAsBytesSync());
    when(() => repository.readObject('api/v1/diagrams/l.svg')).thenAnswer((_) => lightRead.future);

    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.light,
      repository: repository,
    );
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes, variant: DiagramVariant.dark),
      Brightness.light,
      repository: repository,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await settleContent(tester);
    lightRead.complete(lightBytes);
    await settleContent(tester);

    final loader = tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader as SvgBytesLoader;
    expect(loader.bytes, darkBytes);
    expect(frameDecoration(tester).color, const Color(0xFF333333));
    verify(() => repository.readObject('api/v1/diagrams/l.svg')).called(1);
    verify(() => repository.readObject('api/v1/diagrams/d.svg')).called(1);
  });

  testWidgets('an SVG that does not parse shows the unreadable state', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) async => Uint8List.fromList('<svg><g'.codeUnits));
    await pumpInTheme(
      tester,
      const DiagramView(block: block, themes: themes),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.content_unreadable), findsOneWidget);
  });
}
