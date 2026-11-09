@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

const items = [
  QuizItem(question: 'Q1', options: ['One', 'Two', 'Three', 'Four'], answer: 0, explain: 'E1'),
  QuizItem(question: 'Q2', options: ['One', 'Two', 'Three', 'Four'], answer: 1, explain: 'E2'),
  QuizItem(question: 'Q3', options: ['One', 'Two', 'Three', 'Four'], answer: 2, explain: 'E3'),
];

final module = testModule(
  tracks: {
    Track.engineers: testModuleTrack(docs: const {'en': 'api/v1/modules/alpha/first/en.json'}),
    Track.everyone: testModuleTrack(
      docs: const {'en': 'api/v1/modules/alpha/first/everyone/en.json'},
      webPath: 'everyone/courses/alpha/first/',
    ),
  },
);

const _body = [
  ParagraphBlock(inlines: [TextInline(text: 'Body text.')], lead: false),
];

void main() {
  /// Pumps the reader view over [doc] with the quiz feature's panel in its slot.
  Future<void> pumpReader(WidgetTester tester, ModuleDoc doc) async {
    final reader = MockModuleReaderBloc();
    whenListen(
      reader,
      const Stream<ReaderState>.empty(),
      initialState: ReaderWritten(doc: doc, entry: module, moduleCount: 1),
    );
    final router = GoRouter(
      initialLocation: '/reader',
      routes: [
        GoRoute(
          path: '/reader',
          builder: (_, _) => BlocProvider<ModuleReaderBloc>.value(
            value: reader,
            child: const ModuleReaderView(quizBuilder: buildQuizPanel),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(
        router: router,
        content: readyContentBloc(testIndex(modules: [module])),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a For Engineers module with a quiz shows the panel', (tester) async {
    await pumpReader(tester, testDoc(body: _body, quiz: items));

    expect(find.byType(QuizPanel), findsOneWidget);
    expect(find.text('Questions on this module'), findsOneWidget);
    expect(find.text('3 questions on the main points of this module'), findsOneWidget);
  });

  testWidgets('a For Everyone module has no quiz and shows no panel', (tester) async {
    await pumpReader(tester, testDoc(track: Track.everyone, body: _body));

    expect(find.byType(QuizPanel), findsNothing);
    expect(find.text('Questions on this module'), findsNothing);
  });
}
