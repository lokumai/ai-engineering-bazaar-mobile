@Tags(['widget'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/image_full_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
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

void main() {
  late MockContentRepository repository;
  setUpAll(() => S.load(const Locale('en')));
  setUp(() => repository = MockContentRepository());

  testWidgets('the space is reserved at the block aspect ratio before the bytes arrive', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) => Completer<Uint8List>().future);
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await tester.pump();

    expect(tester.getSize(find.byType(FigureImage)), const Size(390, 195));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a decoded image carries its alt text', (tester) async {
    final png = File('test/fixtures/content/src/course-images/alpha/figure.png').readAsBytesSync();
    when(() => repository.readObject(image.src)).thenAnswer((_) async => Uint8List.fromList(png));
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await settleContent(tester);

    expect(tester.widget<Image>(find.byType(Image)).semanticLabel, 'A figure');
    expect(find.text(S.current.content_unreadable), findsNothing);
    expect(tester.getSize(find.byType(FigureImage)), const Size(390, 195));
  });

  testWidgets('a tap opens the image full screen, to zoom, and the close button comes back', (tester) async {
    final semantics = tester.ensureSemantics();
    final png = File('test/fixtures/content/src/course-images/alpha/figure.png').readAsBytesSync();
    when(() => repository.readObject(image.src)).thenAnswer((_) async => Uint8List.fromList(png));
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await settleContent(tester);
    expect(find.byKey(FigureImage.expandKey), findsOneWidget, reason: 'the mark that it opens full screen');
    expect(
      tester.getSemantics(find.bySemanticsLabel('A figure')),
      matchesSemantics(
        isImage: true,
        isButton: true,
        hasTapAction: true,
        label: 'A figure',
        hint: 'Open the image full screen',
      ),
    );

    await tester.tap(find.byType(FigureImage));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFullScreen), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).maxScale, 6);
    expect(tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor, ImageFullScreen.ground);
    expect(find.bySemanticsLabel('A figure'), findsOneWidget, reason: 'named by its alt text full screen too');

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFullScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets('a missing object shows the alt text and the unreadable line', (tester) async {
    when(() => repository.readObject(any())).thenThrow(const ContentMissingException('course-images/alpha/figure.png'));
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await settleContent(tester);

    expect(find.text('A figure'), findsOneWidget);
    expect(find.text(S.current.content_unreadable), findsOneWidget);
    expect(tester.getSize(find.byType(FigureImage)), const Size(390, 195));
  });

  testWidgets('bytes that do not decode show the same state', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await settleContent(tester);

    expect(find.text('A figure'), findsOneWidget);
    expect(find.text(S.current.content_unreadable), findsOneWidget);
    expect(tester.getSize(find.byType(FigureImage)), const Size(390, 195));
    expect(find.byKey(FigureImage.expandKey), findsNothing, reason: 'nothing to open');
  });

  group('at text scale 2.0 the unreadable state grows past the reserved space', () {
    const wide = ImageBlock(
      number: '10.5',
      title: 'A wide figure',
      note: null,
      src: 'course-images/alpha/wide.png',
      alt: 'A wide figure whose picture is three times as wide as it is tall',
      width: 1612,
      height: 524,
    );

    Future<void> expectWhole(WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpInTheme(tester, const FigureImage(block: wide), Brightness.light, repository: repository);
      await settleContent(tester);

      expect(tester.takeException(), isNull);
      final frame = tester.getRect(find.byType(FigureImage));
      expect(frame.height, greaterThan(390 * 524 / 1612));
      for (final text in [wide.alt, S.current.content_unreadable]) {
        final rect = tester.getRect(find.text(text));
        expect(frame.contains(rect.topLeft) && frame.contains(rect.bottomRight - const Offset(0.01, 0.01)), isTrue);
      }
    }

    testWidgets('for a missing object', (tester) async {
      when(() => repository.readObject(any())).thenThrow(const ContentMissingException('course-images/alpha/wide.png'));
      await expectWhole(tester);
    });

    testWidgets('for bytes that do not decode', (tester) async {
      when(() => repository.readObject(any())).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
      await expectWhole(tester);
    });
  });

  testWidgets('an error other than missing or corrupt is not swallowed', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) async => throw StateError('x'));
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await tester.pump();

    expect(tester.takeException(), isA<StateError>());
  });
}
