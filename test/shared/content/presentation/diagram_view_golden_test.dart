import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/content_builders.dart';
import '../../../support/golden_app.dart';
import '../../../support/test_env.dart';

const _diagrams = 'test/fixtures/content/src/api/v1/diagrams';

/// The fixture diagrams the web finaliser drew (A36), by kind: the light then the dark SVG, and a box height that
/// holds the frame at 390 wide. The golden group sizes its cells by intrinsic height, which the view's
/// [LayoutBuilder] cannot answer, so each cell has a fixed size with the frame at its top.
const _fixtures = {
  'flowchart': ('77235fba878b47f1d72f180d8babf2c4.svg', '9bb8502b0371cba0d2e5b7e98362455e.svg', 130.0),
  'mindmap': ('c63f57d179cfa40d893a096c156c03d0.svg', 'da1edd2a0129f03d838131d67f7ca336.svg', 380.0),
};

/// A [DiagramView] 390 wide over the fixture [kind] in [variant], fixed so the golden does not depend on the theme.
Widget _diagram(String kind, DiagramVariant variant) {
  final (light, dark, height) = _fixtures[kind]!;
  final file = switch (variant) {
    DiagramVariant.light => light,
    DiagramVariant.dark => dark,
  };
  final repository = MockContentRepository();
  final bytes = File('$_diagrams/$file').readAsBytesSync();
  when(() => repository.readObject('api/v1/diagrams/$file')).thenAnswer((_) async => Uint8List.fromList(bytes));
  return RepositoryProvider<IContentRepository>.value(
    value: repository,
    child: SizedBox(
      width: 390,
      height: height,
      child: Align(
        alignment: Alignment.topLeft,
        child: DiagramView(
          block: DiagramBlock(
            number: '1.1',
            title: kind,
            svgLight: 'api/v1/diagrams/$light',
            svgDark: 'api/v1/diagrams/$dark',
          ),
          themes: testIndex().diagramThemes,
          variant: variant,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  for (final kind in _fixtures.keys) {
    for (final variant in DiagramVariant.values) {
      goldenTest(
        'DiagramView $kind ${variant.name}',
        fileName: 'diagram_${kind}_${variant.name}',
        pumpWidget: pumpWithLocalizations,
        pumpBeforeTest: settleContent,
        builder: () => GoldenTestGroup(
          columns: 1,
          children: [GoldenTestScenario(name: '$kind ${variant.name}', child: _diagram(kind, variant))],
        ),
      );
    }
  }
}
