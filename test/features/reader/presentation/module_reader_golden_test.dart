import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';
import '../../../support/content_fixture.dart';
import '../../../support/golden_app.dart';
import '../../../support/test_env.dart';

const _diagrams = 'test/fixtures/content/src/api/v1/diagrams';
const _flowLight = 'api/v1/diagrams/flow-light.svg';
const _flowDark = 'api/v1/diagrams/flow-dark.svg';

List<Inline> _text(String text) => [TextInline(text: text)];

/// A written module with the parts of the reader in the web's order, the fixture flowchart among them, not complete.
final _written = ReaderWritten(
  doc: testDoc(
    title: 'First Module',
    prerequisites: [testRef(key: 'alpha/zero', number: 0, title: 'Zero')],
    objectives: const ['Name the parts of a module', 'Read a diagram'],
    body: [
      ParagraphBlock(inlines: _text('A lead paragraph that opens the module.'), lead: true),
      HeadingBlock(depth: 2, id: 'one', mark: null, inlines: _text('Section one')),
      const CodeBlock(
        language: 'dart',
        lines: [
          [
            CodeToken(text: 'final', role: 'keyword', bold: true),
            CodeToken(text: ' answer = ', role: null, bold: false),
            CodeToken(text: '42', role: 'number', bold: false),
            CodeToken(text: ';', role: null, bold: false),
          ],
        ],
      ),
      TableBlock(
        number: '1',
        title: 'A table',
        rowHeaders: true,
        align: const [null, null],
        head: [
          Cell(inlines: _text('Name')),
          Cell(inlines: _text('Value')),
        ],
        rows: [
          [Cell(inlines: _text('Alpha')), Cell(inlines: _text('1'))],
        ],
      ),
      const DiagramBlock(number: '1.1', title: 'A flow', svgLight: _flowLight, svgDark: _flowDark),
    ],
    previous: testRef(key: 'alpha/zero', number: 0, title: 'Zero'),
    next: testRef(),
  ),
  entry: testModule(),
  moduleCount: 2,
);

/// A content repository answering the fixture flowchart in both variants.
MockContentRepository _repository() {
  final repository = MockContentRepository();
  final light = File('$_diagrams/77235fba878b47f1d72f180d8babf2c4.svg').readAsBytesSync();
  final dark = File('$_diagrams/9bb8502b0371cba0d2e5b7e98362455e.svg').readAsBytesSync();
  when(() => repository.readObject(_flowLight)).thenAnswer((_) async => Uint8List.fromList(light));
  when(() => repository.readObject(_flowDark)).thenAnswer((_) async => Uint8List.fromList(dark));
  return repository;
}

Widget _reader({required bool dark}) {
  final bloc = MockModuleReaderBloc();
  whenListen(bloc, const Stream<ReaderState>.empty(), initialState: _written);
  return SizedBox.fromSize(
    size: kGoldenScreenSize,
    child: goldenScreen(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WebLinks>.value(value: const WebLinks(testContentBaseUrl)),
          RepositoryProvider<IContentRepository>.value(value: _repository()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ModuleReaderBloc>.value(value: bloc),
            BlocProvider<ContentBloc>.value(value: readyContentBloc(testIndex())),
            BlocProvider<RecordBloc>.value(value: readyRecordBloc()),
          ],
          child: const ModuleReaderView(),
        ),
      ),
      dark: dark,
    ),
  );
}

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest(
    'ModuleReader light',
    fileName: 'module_reader_light',
    pumpBeforeTest: settleContent,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'written', child: _reader(dark: false))],
    ),
  );

  goldenTest(
    'ModuleReader dark',
    fileName: 'module_reader_dark',
    pumpBeforeTest: settleContent,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'written', child: _reader(dark: true))],
    ),
  );
}
