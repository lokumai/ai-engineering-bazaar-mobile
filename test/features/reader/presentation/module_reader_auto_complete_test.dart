@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/reader/domain/read_enough.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';

/// A module read to its end, and on the screen for a third of its minutes, is marked completed as it is left (the
/// owner, 2026-11-18). The fixture's alpha/first is 20 minutes: 400 seconds count it read.

ParagraphBlock _p(String text) => ParagraphBlock(inlines: [TextInline(text: text)], lead: false);

final _body = [for (var i = 0; i < 40; i++) _p('Paragraph $i of a long module, read from its top to its end.')];

final _note = find.byKey(const ValueKey('reader-auto-completed'));

typedef _Pumped = ({GoRouter router, RecordBloc record, ReadingPlacesBloc places, MemoryReadingPlaceStore store});

Future<_Pumped> _pump(WidgetTester tester, {ReadingPlace? place, RecordData? record}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((_) async => testDoc(body: _body));
  final store = MemoryReadingPlaceStore({readingPlaceKey(Track.engineers, 'alpha/first'): ?place});
  final places = ReadingPlacesBloc(store: store)..add(const ReadingPlacesStarted());
  addTearDown(places.close);
  await places.stream.first;
  final bloc = readyRecordBloc(record);
  final router = AppRouterFactory(initialLocation: '/courses/alpha/first').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, record: bloc, repository: repository, places: places));
  await tester.pumpAndSettle();
  return (router: router, record: bloc, places: places, store: store);
}

/// The completion toggles sent to the record for alpha/first.
List<CompletionToggled> _toggles(RecordBloc record) => [
  for (final event in verify(() => record.add(captureAny())).captured)
    if (event case final CompletionToggled toggle when toggle.key == 'alpha/first') toggle,
];

/// Whether any event reached the record.
bool _sent(RecordBloc record) {
  try {
    return _toggles(record).isNotEmpty;
  } on TestFailure {
    return false;
  }
}

Future<void> _toEnd(WidgetTester tester) async {
  await tester.fling(find.byType(SingleChildScrollView).first, const Offset(0, -30000), 9000);
  await tester.pumpAndSettle();
}

Future<void> _leave(WidgetTester tester, GoRouter router) async {
  router.go('/');
  await tester.pumpAndSettle();
}

void main() {
  test('read enough: its end reached and a third of its minutes spent', () {
    expect(readEnough(reachedEnd: true, seconds: 400, minutes: 20), isTrue);
    expect(readEnough(reachedEnd: true, seconds: 399, minutes: 20), isFalse);
    expect(readEnough(reachedEnd: false, seconds: 4000, minutes: 20), isFalse);
  });

  testWidgets('read to its end, long enough: marked completed as it is left, with Undo', (tester) async {
    final (:router, :record, places: _, store: _) = await _pump(tester);
    await tester.pump(const Duration(seconds: 300));
    await _toEnd(tester);
    await tester.pump(const Duration(seconds: 100));
    await _leave(tester, router);

    expect(_toggles(record), hasLength(1));
    expect(find.descendant(of: _note, matching: find.text('Marked as completed')), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_toggles(record), hasLength(1), reason: 'the Undo sends the toggle again, taking the completion back');
  });

  testWidgets('a quick scroll to the end is not a read', (tester) async {
    final (:router, :record, places: _, :store) = await _pump(tester);
    await _toEnd(tester);
    await tester.pump(const Duration(seconds: 60));
    await _leave(tester, router);

    expect(_sent(record), isFalse);
    expect(_note, findsNothing);
    final kept = (await store.load()).values.single;
    expect(kept.seconds, inInclusiveRange(60, 70), reason: 'the time spent is kept with the place');
  });

  testWidgets('long enough but not to its end: not a read', (tester) async {
    final (:router, :record, places: _, store: _) = await _pump(tester);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 900));
    await _leave(tester, router);

    expect(_sent(record), isFalse);
  });

  testWidgets('the time adds up over visits', (tester) async {
    final (:router, :record, places: _, store: _) = await _pump(
      tester,
      place: ReadingPlace(offset: 0, share: 0, at: DateTime.utc(2026, 11, 18), seconds: 390),
    );
    await _toEnd(tester);
    await tester.pump(const Duration(seconds: 15));
    await _leave(tester, router);

    expect(_toggles(record), hasLength(1));
  });

  testWidgets('a module already completed is left as it is', (tester) async {
    final (:router, :record, places: _, store: _) = await _pump(
      tester,
      record: signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-18T10:00:00.000Z'),
    );
    await tester.pump(const Duration(seconds: 500));
    await _toEnd(tester);
    await _leave(tester, router);

    expect(_sent(record), isFalse);
    expect(_note, findsNothing);
  });

  // Review 4, finding 3: the time on the screen ran on under a page opened over the module, so a module flicked to its
  // end and left under the next one was marked completed by the time spent reading that one.
  testWidgets('time under a page opened over it is not time on the screen', (tester) async {
    final (:router, :record, places: _, store: _) = await _pump(tester);
    await _toEnd(tester);
    unawaited(router.push('/courses/alpha/second'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 600));
    router.pop();
    await tester.pumpAndSettle();
    await _leave(tester, router);

    expect(_sent(record), isFalse);
  });

  // Review 5, finding 13: a place kept during the visit already holds the visit's seconds, and the page built again
  // with it, as the router does when a page is opened over it, added them a second time.
  testWidgets('the time of this visit counts once, whatever places it keeps on the way', (tester) async {
    final (:router, :record, places: _, :store) = await _pump(tester);
    await tester.pump(const Duration(seconds: 150));
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    unawaited(router.push('/courses/alpha/second'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 150));
    await _toEnd(tester);
    await _leave(tester, router);

    expect(_sent(record), isFalse, reason: 'about 300 seconds, short of the 400 that count it read');
    expect((await store.load()).values.single.seconds, inInclusiveRange(300, 320));
  });
}
