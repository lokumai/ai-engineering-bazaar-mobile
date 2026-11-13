@Tags(['widget'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/image_full_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/animated_bytes.dart';
import '../../../support/content_builders.dart';

/// A PNG of [width] by [height] pixels, drawn in a real wait because the engine encodes outside the fake clock.
Future<Uint8List> _pngOf(WidgetTester tester, int width, int height) async => (await tester.runAsync(() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF2F8C86),
  );
  final picture = await recorder.endRecording().toImage(width, height);
  final data = await picture.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}))!;

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

  group('an image is decoded at the width it is drawn at, and no wider', () {
    testWidgets('a photo wider than the page is decoded at the page width in device pixels', (tester) async {
      final png = await _pngOf(tester, 2000, 1000);
      when(() => repository.readObject(image.src)).thenAnswer((_) async => png);
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);

      final ratio = tester.view.devicePixelRatio;
      final decoded = tester.widget<RawImage>(find.byType(RawImage)).image!;
      expect(decoded.width, (390 * ratio).ceil());
      expect(decoded.height, (390 * ratio / 2).round(), reason: 'its shape kept');
      expect(tester.getSize(find.byType(FigureImage)), const Size(390, 195), reason: 'drawn as large as before');
    });

    testWidgets('a small image is not made larger', (tester) async {
      final png = File('test/fixtures/content/src/course-images/alpha/figure.png').readAsBytesSync();
      when(() => repository.readObject(image.src)).thenAnswer((_) async => Uint8List.fromList(png));
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);

      expect(tester.widget<RawImage>(find.byType(RawImage)).image!.width, 4);
    });

    testWidgets('full screen decodes it whole, to zoom', (tester) async {
      final png = await _pngOf(tester, 2000, 1000);
      when(() => repository.readObject(image.src)).thenAnswer((_) async => png);
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);
      await tester.tap(find.byType(FigureImage));
      await tester.pumpAndSettle();
      await settleContent(tester);

      final full = find.descendant(of: find.byType(ImageFullScreen), matching: find.byType(RawImage));
      expect(tester.widget<RawImage>(full).image!.width, 2000);
    });
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

  group('the replay button (web M115, D136)', () {
    testWidgets('an animated image carries it, a button of its own named Replay, beside the full-screen mark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      when(() => repository.readObject(image.src)).thenAnswer((_) async => gifOf(2));
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);

      expect(find.byKey(FigureImage.replayKey), findsOneWidget);
      expect(find.byKey(FigureImage.expandKey), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Replay')),
        matchesSemantics(isButton: true, hasTapAction: true, label: 'Replay', tooltip: 'Replay'),
      );
      expect(tester.getSize(find.byKey(FigureImage.replayKey)), const Size(48, 48));
      semantics.dispose();
    });

    testWidgets('a tap plays it again from its start and does not open it full screen', (tester) async {
      when(() => repository.readObject(image.src)).thenAnswer((_) async => gifOf(2));
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);
      expect(tester.widget<Image>(find.byType(Image)).key, const ValueKey(0));

      final shown = tester.widget<Image>(find.byType(Image)).image;
      final key = await shown.obtainKey(ImageConfiguration.empty);
      expect(imageCache.containsKey(key), isTrue);

      await tester.tap(find.byKey(FigureImage.replayKey));
      expect(
        imageCache.containsKey(key),
        isFalse,
        reason: 'the image as decoded, at its width, is put out of the cache',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<Image>(find.byType(Image)).key, const ValueKey(1), reason: 'drawn afresh, from frame 0');
      expect(find.byType(ImageFullScreen), findsNothing);
    });

    testWidgets('full screen, an animated image carries it too, and a tap plays it again', (tester) async {
      when(() => repository.readObject(image.src)).thenAnswer((_) async => gifOf(2));
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);
      await tester.tapAt(tester.getCenter(find.byType(FigureImage)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final replay = find.byKey(ImageFullScreen.replayKey);
      expect(replay, findsOneWidget);
      expect(find.byTooltip('Replay'), findsWidgets);
      Image fullScreen() =>
          tester.widget<Image>(find.descendant(of: find.byType(ImageFullScreen), matching: find.byType(Image)));
      expect(fullScreen().key, const ValueKey(0));

      await tester.tap(replay);
      await tester.pump();
      expect(fullScreen().key, const ValueKey(1), reason: 'drawn afresh, from frame 0');
    });

    testWidgets('a still image has none', (tester) async {
      final png = File('test/fixtures/content/src/course-images/alpha/figure.png').readAsBytesSync();
      when(() => repository.readObject(image.src)).thenAnswer((_) async => Uint8List.fromList(png));
      await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
      await settleContent(tester);

      expect(find.byKey(FigureImage.expandKey), findsOneWidget);
      expect(find.byKey(FigureImage.replayKey), findsNothing);

      await tester.tap(find.byType(FigureImage));
      await tester.pumpAndSettle();
      expect(find.byType(ImageFullScreen), findsOneWidget);
      expect(find.byKey(ImageFullScreen.replayKey), findsNothing, reason: 'nor full screen');
    });
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
