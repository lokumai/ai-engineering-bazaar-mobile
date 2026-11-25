@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

void main() {
  // Review 12, C1: the completion row in view counted as read to the end however the page got there, and the time of
  // earlier visits made up the rest.
  testWidgets('a search hit in the last section, only looked at, does not mark a half-read module completed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer(
      (_) async => testDoc(
        toc: const [
          TocEntry(id: 'start', text: 'Start', depth: 2, mark: null),
          TocEntry(id: 'last', text: 'Last', depth: 2, mark: null),
        ],
        body: [
          const HeadingBlock(
            depth: 2,
            id: 'start',
            mark: null,
            inlines: [TextInline(text: 'Start')],
          ),
          for (var i = 0; i < 40; i++) _p('Paragraph $i of a long module, read from its top to its end.'),
          const HeadingBlock(
            depth: 2,
            id: 'last',
            mark: null,
            inlines: [TextInline(text: 'Last')],
          ),
          _p('A short last section with the word searched.'),
        ],
      ),
    );
    // Read the first part yesterday for 15 minutes (a 20-minute module needs 400 s).
    final store = MemoryReadingPlaceStore({
      readingPlaceKey(Track.engineers, 'alpha/first'): ReadingPlace(
        heading: 'start',
        offset: 300,
        share: 0.3,
        at: DateTime.utc(2026, 11, 20),
        seconds: 900,
      ),
    });
    final places = ReadingPlacesBloc(store: store)..add(const ReadingPlacesStarted());
    addTearDown(places.close);
    await places.stream.first;
    final record = readyRecordBloc();
    final router = const AppRouterFactory().create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, record: record, repository: repository, places: places));
    await tester.pumpAndSettle();

    router.push(
      '/courses/alpha/first',
      extra: const ReaderTarget(fragment: 'last', query: 'searched'),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    router.go('/');
    await tester.pumpAndSettle();

    verifyNever(() => record.add(any(that: isA<CompletionSet>())));
  });
}
