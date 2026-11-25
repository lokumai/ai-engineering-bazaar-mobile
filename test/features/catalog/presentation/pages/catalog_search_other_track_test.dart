@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_search.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/pager.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/content_builders.dart';

/// The search's other track (plan 12.7): every For Engineers document speaks of a tokenizer, no For Everyone one does.
MockContentRepository _repository() {
  final repository = MockContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((invocation) async {
    final path = invocation.positionalArguments.single as String;
    final key = path.split('/').skip(3).take(2).join('/');
    final everyone = path.contains('/everyone/');
    return testDoc(
      key: key,
      title: 'Module $key',
      next: key == 'alpha/first'
          ? const Ref(key: 'alpha/second', number: 2, title: 'Second', drawn: true, track: Track.engineers, lang: 'en')
          : null,
      body: [
        ParagraphBlock(
          inlines: [TextInline(text: everyone ? 'A gentle story about reading.' : 'The tokenizer splits the text.')],
          lead: false,
        ),
      ],
    );
  });
  when(() => repository.readObject(any())).thenAnswer((_) async => throw UnimplementedError());
  return repository;
}

Future<(GoRouter, TrackCubit)> _pumpEveryone(WidgetTester tester) async {
  final track = TrackCubit()..select(Track.everyone);
  addTearDown(track.close);
  final router = AppRouterFactory(initialLocation: '/everyone/sheets').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, repository: _repository(), track: track));
  await tester.pumpAndSettle();
  return (router, track);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(CatalogSearchField.settle);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nothing in For Everyone: For Engineers\' hits, which open without changing the track', (tester) async {
    final (router, track) = await _pumpEveryone(tester);

    await _type(tester, 'tokenizer');

    expect(find.text('Nothing found for “tokenizer” in this track.'), findsOneWidget);
    expect(find.textContaining('In For Engineers · '), findsOneWidget);
    final other = find.byKey(const ValueKey('catalog-search-other-track'));
    await tester.tap(find.descendant(of: other, matching: find.textContaining('Module ')).first);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, startsWith('/courses/'), reason: 'the For Engineers module');
    expect((router.state.extra! as ReaderTarget).visit, isTrue);
    expect(track.state, Track.everyone, reason: 'the reader\'s track stays (plan 12.7)');

    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/everyone/sheets');
    expect(track.state, Track.everyone);
  });

  testWidgets('a hit in For Everyone: For Engineers is not shown', (tester) async {
    await _pumpEveryone(tester);

    await _type(tester, 'story');

    expect(find.byKey(const ValueKey('catalog-search-other-track')), findsNothing);
    expect(find.textContaining('In For Engineers'), findsNothing);
  });

  // Review 11, features 9: Next in a module opened as a visit went on without the flag, and the track switched.
  testWidgets("Next in a module of the other track, opened as a visit, keeps the reader's track", (tester) async {
    final (router, track) = await _pumpEveryone(tester);
    router.push('/courses/alpha/first', extra: const ReaderTarget(visit: true)).ignore();
    await tester.pumpAndSettle();
    expect(track.state, Track.everyone);

    final next = find.descendant(of: find.byType(Pager), matching: find.byType(FilledButton));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, isNot('/courses/alpha/first'));
    expect(router.state.uri.path, startsWith('/courses/'));
    expect(track.state, Track.everyone);
  });
}
