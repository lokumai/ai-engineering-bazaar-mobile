@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/transfer/presentation/transfer_page.dart';
import 'package:ai_engineering_bazaar/infrastructure/transfer/deflate_transfer_packer.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/accessibility.dart';
import '../../support/bazaar_app_harness.dart';

const _compact =
    '{"v":1,"e":{"alpha/first":["mvz1mz0r","a1b2c3d",[0]],"alpha/second":["","",[1]]},"y":{"alpha/first":["mvz1mz0r","",[]]},"d":[]}';

/// A record bloc that answers every transfer with [result].
MockRecordBloc _recordAnswering(TransferMergeResult result, List<TransferMerged> merged) {
  final bloc = MockRecordBloc();
  whenListen(bloc, const Stream<RecordState>.empty(), initialState: const RecordLoading());
  when(() => bloc.add(any())).thenAnswer((invocation) {
    if (invocation.positionalArguments.first case final TransferMerged event) {
      merged.add(event);
      event.reply.complete(result);
    }
  });
  return bloc;
}

GoRouter _router(String payload) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => TransferPage(payload: payload),
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

Future<void> _pump(
  WidgetTester tester,
  String payload,
  RecordBloc record, {
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(bazaarTestApp(router: _router(payload), record: record, platform: platform, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(const RecordStarted()));

  testWidgets('shows what the link carries by track, and adds it only when asked (plan 17.1)', (tester) async {
    final merged = <TransferMerged>[];
    await _pump(
      tester,
      const DeflateTransferPacker().pack(_compact),
      _recordAnswering(TransferMergeResult.added, merged),
    );

    expect(find.text('Progress from a link'), findsOneWidget);
    expect(find.text('For Engineers'), findsOneWidget);
    expect(find.text('1 module completed'), findsNWidgets(2));
    expect(find.text('2 checklist items ticked'), findsOneWidget, reason: 'For Everyone carries no tick, so no line');
    expect(merged, isEmpty, reason: 'nothing is added on open');
    await expectPlatformGuidelines(tester, platform: TargetPlatform.android);

    await tester.tap(find.byKey(const ValueKey('transfer-add')));
    await tester.pumpAndSettle();

    expect(merged.single.progress.engineers.keys, ['alpha/first', 'alpha/second']);
    expect(find.text('Added. Nothing on this device was removed.'), findsOneWidget);
    expect(find.byKey(const ValueKey('transfer-add')), findsNothing);
  });

  // The owner, 2026-11-19: a link of ticks alone must not read as an empty one.
  testWidgets('a link of ticks alone says the ticks, not only that no module is completed', (tester) async {
    await _pump(
      tester,
      const DeflateTransferPacker().pack('{"v":1,"e":{"a/b":["","",[0]]},"y":{"a/b":["","",[1,2]]},"d":[]}'),
      _recordAnswering(TransferMergeResult.added, []),
    );

    expect(find.text('0 modules completed'), findsNWidgets(2), reason: 'as the website says it');
    expect(find.text('1 checklist item ticked'), findsOneWidget);
    expect(find.text('2 checklist items ticked'), findsOneWidget);
  });

  // Review 9, finding 9: after "Not added" the Add button was gone, and the link had to be opened again.
  testWidgets('not added, it says so and Add tries again', (tester) async {
    final merged = <TransferMerged>[];
    await _pump(
      tester,
      const DeflateTransferPacker().pack(_compact),
      _recordAnswering(TransferMergeResult.notAdded, merged),
    );
    await tester.tap(find.byKey(const ValueKey('transfer-add')));
    await tester.pumpAndSettle();
    expect(find.text('Not added. Nothing on this device changed; Add tries again.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transfer-add')));
    await tester.pumpAndSettle();
    expect(merged, hasLength(2));
  });

  testWidgets('says when there was nothing new', (tester) async {
    await _pump(
      tester,
      const DeflateTransferPacker().pack(_compact),
      _recordAnswering(TransferMergeResult.nothingNew, []),
    );
    await tester.tap(find.byKey(const ValueKey('transfer-add')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing new: this device already has all of it.'), findsOneWidget);
  });

  testWidgets('a link it cannot read offers nothing to add', (tester) async {
    await _pump(tester, 'not-a-payload', _recordAnswering(TransferMergeResult.added, []));
    expect(find.text("This link cannot be read. Make a new one on the website's Progress page."), findsOneWidget);
    expect(find.byKey(const ValueKey('transfer-add')), findsNothing);
  });

  testWidgets('meets the platform guidelines', (tester) async {
    await _pump(
      tester,
      const DeflateTransferPacker().pack(_compact),
      _recordAnswering(TransferMergeResult.added, []),
      platform: defaultTargetPlatform,
    );
    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);

  testWidgets('at text scale 2 the counts wrap and Add stays whole and reachable', (tester) async {
    await pumpAtTextScale(
      tester,
      bazaarTestApp(
        router: _router(const DeflateTransferPacker().pack(_compact)),
        record: _recordAnswering(TransferMergeResult.added, []),
      ),
      scale: 2.0,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'no overflow');
    expect(find.text('2 checklist items ticked'), findsOneWidget);
    // The page is a lazy list: at this scale Add is built only once scrolled to.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('transfer-add')), 200);
    await tester.pumpAndSettle();
    expectHittable(tester, find.byKey(const ValueKey('transfer-add')));
  });

  testWidgets('reads in Turkish and in Persian, right to left', (tester) async {
    final packed = const DeflateTransferPacker().pack(_compact);
    await _pump(tester, packed, _recordAnswering(TransferMergeResult.added, []), locale: const Locale('tr'));
    expect(find.text('Bağlantıdaki ilerleme'), findsOneWidget);
    expect(find.text('1 modül tamamlandı'), findsNWidgets(2));
    expect(find.text('2 kontrol listesi maddesi işaretli'), findsOneWidget);

    await _pump(tester, packed, _recordAnswering(TransferMergeResult.added, []), locale: const Locale('fa'));
    expect(find.text('پیشرفت از یک پیوند'), findsOneWidget);
    expect(find.text('2 مورد از فهرست بررسی علامت خورده'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('پیشرفت از یک پیوند'))), TextDirection.rtl);
  });
}
