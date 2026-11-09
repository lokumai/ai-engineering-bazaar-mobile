@Tags(['widget'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
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
  });

  testWidgets('an error other than missing or corrupt is not swallowed', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) async => throw StateError('x'));
    await pumpInTheme(tester, const FigureImage(block: image), Brightness.light, repository: repository);
    await tester.pump();

    expect(tester.takeException(), isA<StateError>());
  });
}
