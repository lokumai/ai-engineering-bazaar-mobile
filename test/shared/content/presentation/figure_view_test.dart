@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

const image = ImageBlock(
  number: '2.1',
  title: 'A title',
  note: 'A note.',
  src: 'course-images/alpha/figure.png',
  alt: 'A figure',
  width: 800,
  height: 400,
);

/// The leaf spans of the caption with their styles.
List<(String, TextStyle)> captionSpans(WidgetTester tester, Finder caption) {
  final root = tester.widget<Text>(caption).textSpan! as TextSpan;
  return [for (final child in root.children!.cast<TextSpan>()) (child.text!, root.style!.merge(child.style))];
}

void main() {
  setUpAll(() => S.load(const Locale('en')));

  testWidgets('an image caption sits below the image with the note under it', (tester) async {
    await pumpBlocks(tester, const [image]);

    final caption = find.text('FIG. 2.1 · A title');
    expect(caption, findsOneWidget);
    expect(tester.getTopLeft(caption).dy, tester.getBottomLeft(find.byType(FigureImage)).dy + 9);
    final note = find.text('A note.');
    expect(tester.getTopLeft(note).dy, tester.getBottomLeft(caption).dy + 4);
    expect(tester.widget<Text>(note).style!.color, BazaarColors.light.onSurfaceMuted);
    expect(tester.widget<Text>(note).style!.fontSize, BazaarType.meta.size);

    final [(label, labelStyle), (rest, restStyle)] = captionSpans(tester, caption);
    expect(label, 'FIG. 2.1');
    expect(labelStyle.color, BazaarColors.light.onSurface);
    expect(labelStyle.fontWeight, FontWeight.w600);
    expect(labelStyle.fontSize, BazaarType.meta.size);
    expect(rest, ' · A title');
    expect(restStyle.color, BazaarColors.light.onSurfaceMuted);
    expect(restStyle.fontWeight, FontWeight.w400);
    expect(restStyle.fontSize, BazaarType.meta.size);
    expect(find.byType(FigureView), findsOneWidget);
  });

  testWidgets('an image without a note or title shows the label alone', (tester) async {
    await pumpBlocks(tester, const [
      ImageBlock(number: '3', title: null, note: null, src: 's.png', alt: '', width: 10, height: 10),
    ]);

    expect(find.text('FIG. 3'), findsOneWidget);
    expect(captionSpans(tester, find.text('FIG. 3')), hasLength(1));
  });

  testWidgets('a diagram caption sits below the frame', (tester) async {
    await pumpBlocks(tester, const [
      DiagramBlock(number: '1.1', title: null, svgLight: 'api/v1/diagrams/l.svg', svgDark: 'api/v1/diagrams/d.svg'),
    ]);

    final caption = find.text('FIG. 1.1');
    expect(caption, findsOneWidget);
    expect(tester.getTopLeft(caption).dy, tester.getBottomLeft(find.byType(DiagramView)).dy + 9);
    expect(tester.widget<DiagramView>(find.byType(DiagramView)).themes, testIndex().diagramThemes);
  });

  testWidgets('each figure carries its caption once in semantics', (tester) async {
    await pumpBlocks(tester, const [
      image,
      DiagramBlock(number: '1.1', title: null, svgLight: 'api/v1/diagrams/l.svg', svgDark: 'api/v1/diagrams/d.svg'),
    ]);

    // The image caption is read as text after the image's alt text; the diagram is labelled with its caption by
    // DiagramView, so its visible caption is not read a second time.
    expect(find.bySemanticsLabel('FIG. 2.1 · A title'), findsOneWidget);
    expect(find.bySemanticsLabel('FIG. 1.1'), findsOneWidget);
  });
}
