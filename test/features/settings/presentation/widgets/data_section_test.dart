@Tags(['widget'])
library;

import 'dart:convert';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_section.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/presentation/record_write_notice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../data_host.dart';

/// The reader's data on the Settings page (plan 1AB): what the progress page held under its cards.

/// A backup file whose record has `alpha/second` completed.
const _restorable =
    '{"schema":1,"savedAt":"2026-03-15T10:00:00.000Z","data":{"sheets":{"alpha/second":{"signedOff":"2026-03-15T10:00:00.000Z"}}}}';

RecordData _firstCompleted() => signOff(RecordData.empty, 'alpha/first', null, '2026-03-15T10:00:00.000Z');

Future<GoRouter> _pump(WidgetTester tester, {required RecordBloc record, IBackupGateway? gateway}) async {
  final router = const AppRouterFactory(initialLocation: '/settings').create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, record: record, backupGateway: gateway));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerAllFallbackValues);

  testWidgets('Settings carries the data line under Your progress, before the content status', (tester) async {
    await _pump(tester, record: readyRecordBloc());

    expect(find.byType(DataSection), findsOneWidget);
    expect(find.bySemanticsLabel('Record status'), findsNothing);
    expect(find.byType(RecordWriteNotice), findsNothing);
    final section = tester.getTopLeft(find.text('Your progress')).dy;
    final backUp = tester.getTopLeft(find.text('Back up')).dy;
    expect(section, lessThan(backUp));
    await tester.ensureVisible(find.text('Content'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Back up')).dy, lessThan(tester.getTopLeft(find.text('Content')).dy));
  });

  testWidgets('the quarantine notice and the write notice sit above the data line', (tester) async {
    final record = recordBlocAt(
      quarantine: QuarantineReason.newer,
      quarantineKept: true,
      writeState: const WriteQuota(),
    );
    await _pump(tester, record: record);

    final quarantine = tester.getTopLeft(find.bySemanticsLabel('Record status')).dy;
    final notice = tester.getTopLeft(find.byType(RecordWriteNotice)).dy;
    final backUp = tester.getTopLeft(find.text('Back up')).dy;
    expect(quarantine, lessThan(notice));
    expect(notice, lessThan(backUp));

    tester.widget<RecordWriteNotice>(find.byType(RecordWriteNotice)).onBackUp();
    await tester.pump();
    final events = verify(() => record.add(captureAny())).captured;
    expect(events.whereType<BackupStarted>(), hasLength(1));
  });

  testWidgets('a pending restore opens the confirmation', (tester) async {
    for (final (answer, replaced) in [('Replace', true), ('Keep my data', false)]) {
      final recordBloc = readyRecordBloc(_firstCompleted()) as MockRecordBloc;
      when(() => recordBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments.first case RecordReplaced(:final reply?)) reply.complete(true);
      });
      final gateway = MockBackupGateway();
      when(gateway.pickJson)
          .thenAnswer((_) async => PickedBackupBytes(bytes: Uint8List.fromList(utf8.encode(_restorable))));
      await _pump(tester, record: recordBloc, gateway: gateway);

      await _tap(tester, find.text('Restore'));
      expect(find.text('Replace the progress on this device?'), findsOneWidget, reason: answer);

      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      if (replaced) {
        verify(() => recordBloc.add(any(that: isA<RecordReplaced>()))).called(1);
        expect(find.text('Restored from the file.'), findsOneWidget);
      } else {
        verifyNever(() => recordBloc.add(any(that: isA<RecordReplaced>())));
      }
    }
  });

  testWidgets('text scale 2.0', (tester) async {
    final router = const AppRouterFactory(initialLocation: '/settings').create();
    addTearDown(router.dispose);
    await pumpAtTextScale(tester, bazaarTestApp(router: router, record: readyRecordBloc()), scale: 2.0);

    expect(tester.takeException(), isNull);
    for (final target in [find.text('Back up'), find.text('Restore'), find.text('Reset')]) {
      await tester.ensureVisible(target);
      await tester.pump();
      expectHittable(tester, target);
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    final router = const AppRouterFactory(initialLocation: '/settings').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      bazaarTestApp(
        platform: defaultTargetPlatform,
        router: router,
        record: recordBlocAt(
          quarantine: QuarantineReason.malformed,
          quarantineKept: true,
          writeState: const WriteQuota(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
