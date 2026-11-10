@Tags(['widget'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/logo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/content_builders.dart';

const _src = 'course-images/alpha/logos/x-mono.svg';
const _square =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" width="20" height="20">'
    '<rect width="20" height="20" fill="#000000"/></svg>';

const _invert = ColorFilter.matrix(<double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]);

void main() {
  late MockContentRepository repository;

  setUp(() {
    repository = MockContentRepository();
    when(() => repository.readObject(_src)).thenAnswer((_) async => Uint8List.fromList(utf8.encode(_square)));
  });

  testWidgets('a logo is 1.1 times the font size tall and out of semantics', (tester) async {
    await pumpInTheme(
      tester,
      const LogoView(src: _src, mono: true, fontSize: 20),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);

    expect(tester.getSize(find.byType(SvgPicture)).height, 22);
    expect(find.descendant(of: find.byType(LogoView), matching: find.byType(ExcludeSemantics)), findsOneWidget);
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('a mono logo is inverted on a dark theme', (tester) async {
    await pumpInTheme(
      tester,
      const LogoView(src: _src, mono: true, fontSize: 20),
      Brightness.dark,
      repository: repository,
    );
    await settleContent(tester);

    final filtered = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(filtered.colorFilter, _invert);
    expect(find.descendant(of: find.byType(ColorFiltered), matching: find.byType(SvgPicture)), findsOneWidget);
  });

  testWidgets('a coloured logo is never inverted', (tester) async {
    await pumpInTheme(
      tester,
      const LogoView(src: _src, mono: false, fontSize: 20),
      Brightness.dark,
      repository: repository,
    );
    await settleContent(tester);

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('a missing logo keeps its square of space and draws nothing', (tester) async {
    when(() => repository.readObject(any())).thenThrow(const ContentMissingException(_src));
    await pumpInTheme(
      tester,
      const Center(child: LogoView(src: _src, mono: true, fontSize: 20)),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);

    expect(find.byType(SvgPicture), findsNothing);
    expect(tester.getSize(find.byType(LogoView)), const Size(22, 22));
  });

  testWidgets('a logo that does not parse keeps its square of space and draws nothing (plan 2.2)', (tester) async {
    when(() => repository.readObject(any())).thenAnswer((_) async => Uint8List.fromList('<svg><g'.codeUnits));
    await pumpInTheme(
      tester,
      const Center(child: LogoView(src: _src, mono: true, fontSize: 20)),
      Brightness.light,
      repository: repository,
    );
    await settleContent(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LogoView)), const Size(22, 22));
    expect(find.descendant(of: find.byType(SvgPicture), matching: find.byKey(LogoView.unreadableKey)), findsOneWidget);
  });
}
