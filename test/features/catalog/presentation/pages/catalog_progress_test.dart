@Tags(['widget'])
library;

import 'dart:convert';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_legend.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/widgets/catalog_overview.dart';
import 'package:flutter/widgets.dart' show Scrollable;
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/fold.dart';

/// The progress inside the catalog (plan 1AB): the stats, the dials, the marks and the legend that the progress page
/// held, on the catalog root of each track.

/// The record with `alpha/first` completed For Engineers.
RecordData _firstCompleted() => signOff(RecordData.empty, 'alpha/first', null, '2026-03-15T10:00:00.000Z');

Future<GoRouter> _pump(WidgetTester tester, {String location = '/sheets', required RecordBloc record}) async {
  final router = AppRouterFactory(initialLocation: location).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, record: record));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String title) => openFold(tester, find.bySemanticsLabel(RegExp('^$title,')));

/// A record store in memory that keeps the last write.
class _MemoryRecordRepository implements IRecordRepository {
  String? lastWritten;

  @override
  Future<RecordLoad> load() async => const RecordLoadEmpty(quarantineKept: false);

  @override
  Future<WriteResult> write(String compactJson) async {
    lastWritten = compactJson;
    return WriteResult.saved;
  }

  @override
  Future<StoredBytes> readStored() async =>
      StoredBytes(record: Uint8List.fromList(utf8.encode('{}')), quarantine: null);

  @override
  Future<void> deleteAll() async {}

  @override
  Future<RestoreResult> restore(StoredBytes bytes) => throw UnimplementedError();

  @override
  Future<void> deleteQuarantine() => throw UnimplementedError();
}

void main() {
  setUpAll(registerAllFallbackValues);

  testWidgets('the stats show the modules completed in the track and the active days', (tester) async {
    final record = signOff(
      signOff(RecordData.empty, 'alpha/first', 'abc1234', '2026-11-08T10:00:00.000Z'),
      'alpha/second',
      'abc1234',
      '2026-11-09T10:00:00.000Z',
    );
    await _pump(tester, record: readyRecordBloc(record));

    // Each stat is read as one line: the number, then its label.
    String spoken(String label) => tester.getSemantics(find.text(label)).label;
    expect(spoken('modules completed'), '2 modules completed');
    expect(spoken('active days'), '2 active days');

    await _pump(tester, location: '/everyone/sheets', record: readyRecordBloc(record));
    expect(spoken('modules completed'), '0 modules completed', reason: 'the count follows the track');
    expect(spoken('active days'), '2 active days', reason: "the days are the record's");
  });

  testWidgets('each level shows its dial, numbered in the index order', (tester) async {
    await _pump(tester, record: readyRecordBloc(_firstCompleted()));

    for (final dial in ['1/3', '0/2', '0/1']) {
      expect(find.text(dial), findsOneWidget, reason: dial);
    }
    expect(find.textContaining('01  Alpha Level'), findsOneWidget);
    expect(find.textContaining('03  Gamma Level'), findsOneWidget);
  });

  testWidgets('prints -- while the record loads, and no stats', (tester) async {
    await _pump(tester, record: loadingRecordBloc());

    for (final dial in ['--/3', '--/2', '--/1']) {
      expect(find.text(dial), findsOneWidget, reason: dial);
    }
    expect(find.textContaining('modules completed'), findsNothing);
  });

  testWidgets('the levels end with the legend', (tester) async {
    await _pump(tester, record: readyRecordBloc());

    await tester.scrollUntilVisible(find.byType(CatalogLegend), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    for (final word in ['Complete', 'Not yet', 'Planned']) {
      expect(
        find.descendant(of: find.byType(CatalogLegend), matching: find.text(word)),
        findsOneWidget,
        reason: word,
      );
    }
    final gamma = tester.getTopLeft(find.byKey(CatalogOverview.levelKey('gamma'))).dy;
    expect(gamma, lessThan(tester.getTopLeft(find.byType(CatalogLegend)).dy));
  });

  testWidgets('a written row toggles the track with revision null, and reads as checked once complete', (tester) async {
    final recordBloc = readyRecordBloc() as MockRecordBloc;
    await _pump(tester, location: '/everyone/sheets', record: recordBloc);
    await _open(tester, 'Alpha Level');
    await _tap(tester, find.bySemanticsLabel('Complete First Module'));

    final event = verify(() => recordBloc.add(captureAny())).captured.single as CompletionToggled;
    expect((event.key, event.revision, event.track), ('alpha/first', null, Track.everyone));

    await _pump(tester, record: readyRecordBloc(_firstCompleted()));
    await _open(tester, 'Alpha Level');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Complete First Module')),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Complete Second Module')),
      isSemantics(hasCheckedState: true, isChecked: false, hasTapAction: true),
    );
  });

  testWidgets('a planned row has no control', (tester) async {
    await _pump(tester, record: readyRecordBloc());
    await _open(tester, 'Alpha Level');

    expect(find.bySemanticsLabel('Complete Third Module'), findsNothing);
    expect(find.bySemanticsLabel('Complete Second Module'), findsOneWidget);
  });

  testWidgets('a For Engineers completion completes For Everyone too, never the reverse (plan 1V)', (tester) async {
    final repository = _MemoryRecordRepository();
    final record = RecordBloc(repository: repository)..add(const RecordStarted());
    addTearDown(record.close);
    await _pump(tester, record: record);
    await _open(tester, 'Alpha Level');

    await _tap(tester, find.bySemanticsLabel('Complete First Module'));
    expect(find.text('1/3'), findsOneWidget);
    expect(repository.lastWritten, contains('"sheets":{"alpha/first":{"signedOff":"'));
    expect(repository.lastWritten, contains('"everyoneSheets":{"alpha/first":{"signedOff":"'));

    await _pump(tester, location: '/everyone/sheets', record: record);
    expect(find.text('1/3'), findsOneWidget, reason: 'carried over from For Engineers');
    await _open(tester, 'Alpha Level');
    await _tap(tester, find.bySemanticsLabel('Complete First Module'));
    expect(find.text('0/3'), findsOneWidget);
    expect(repository.lastWritten, contains('"sheets":{"alpha/first":{"signedOff":"'));

    await _pump(tester, record: record);
    expect(find.text('1/3'), findsOneWidget, reason: 'a For Everyone toggle leaves For Engineers as it is');
  });
}
