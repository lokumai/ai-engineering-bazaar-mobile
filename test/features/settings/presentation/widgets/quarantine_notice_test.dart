@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/quarantine_notice.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../data_host.dart';

const _newer = (
  'PROGRESS WRITTEN BY A NEWER VERSION OF THE APP. NOT READ.',
  'Update the app to read it. The stored record is kept on this device unchanged.',
);
const _malformed = (
  'PROGRESS THIS VERSION OF THE APP COULD NOT READ. NOT READ.',
  'The stored record is not a shape this version of the app can read. It has been copied aside on this device '
      'unchanged rather than discarded, and nothing has been written over it.',
);
const _kept = (
  'A STORED RECORD IS SET ASIDE',
  'An earlier launch could not read the stored progress. Its bytes are kept on this device unchanged.',
);
const _saved = 'Saved a copy of the set-aside record.';
const _notWritten = 'The copy could not be written. The set-aside record is unchanged.';

Finder _button(String label) => find.widgetWithText(TextButton, label);

void main() {
  Future<DataBloc> pumpNotice(
    WidgetTester tester, {
    bool kept = true,
    QuarantineReason? reason,
    DataState state = const DataState(),
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    final (bloc, _) = dataBlocAt(state);
    await pumpDataHost(
      tester,
      const QuarantineNotice(),
      data: bloc,
      record: recordBlocAt(quarantine: reason, quarantineKept: kept),
      platform: platform,
    );
    return bloc;
  }

  testWidgets('nothing while no record is set aside', (tester) async {
    await pumpNotice(tester, kept: false, reason: QuarantineReason.malformed);

    expect(find.descendant(of: find.byType(QuarantineNotice), matching: find.byType(Text)), findsNothing);
  });

  testWidgets('the readout and note follow the reason', (tester) async {
    for (final (reason, (readout, note)) in [
      (QuarantineReason.newer, _newer),
      (QuarantineReason.malformed, _malformed),
      (null, _kept),
    ]) {
      await pumpNotice(tester, reason: reason);
      expect(find.text(readout), findsOneWidget, reason: '$reason');
      expect(find.text(note), findsOneWidget, reason: '$reason');
      expect(find.bySemanticsLabel('Record status'), findsOneWidget);
    }
  });

  testWidgets('the readout and the note are on-surface text', (tester) async {
    await pumpNotice(tester, reason: QuarantineReason.newer);
    final onSurface = Theme.of(tester.element(find.byType(QuarantineNotice))).colorScheme.onSurface;

    for (final text in [_newer.$1, _newer.$2]) {
      expect(tester.widget<Text>(find.text(text)).style!.color, onSurface);
    }
  });

  testWidgets('the notice has a fault edge', (tester) async {
    await pumpNotice(tester);
    final fault = tester.element(find.byType(QuarantineNotice)).bazaarColors.fault;

    final edges = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: find.byType(QuarantineNotice), matching: find.byType(DecoratedBox)),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => (decoration.border as Border?)?.left.color == fault);
    expect(edges, hasLength(1));
  });

  testWidgets('Save a copy adds its event', (tester) async {
    final bloc = await pumpNotice(tester);
    await tester.tap(find.text('Save a copy'));

    expect(verify(() => bloc.add(captureAny())).captured, [isA<QuarantineExportRequested>()]);
  });

  testWidgets('Delete it asks first', (tester) async {
    final bloc = await pumpNotice(tester);
    await tester.tap(find.text('Delete it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any()));

    await tester.tap(find.text('Delete it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(verify(() => bloc.add(captureAny())).captured, [isA<QuarantineDeleteConfirmed>()]);
  });

  testWidgets('the copy lines are a live region', (tester) async {
    await pumpNotice(tester, state: const DataState(quarantineCopy: QuarantineCopy.saved));
    expect(find.text(_saved), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(_saved),
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.liveRegion == true),
      ),
      findsOneWidget,
    );

    await pumpNotice(tester, state: const DataState(quarantineCopy: QuarantineCopy.notWritten));
    expect(find.text(_notWritten), findsOneWidget);
    expect(find.text(_saved), findsNothing);

    await pumpNotice(tester);
    expect(find.text(_saved), findsNothing);
    expect(find.text(_notWritten), findsNothing);
  });

  testWidgets('the actions are off while a flow runs', (tester) async {
    await pumpNotice(tester, state: const DataState(busy: DataBusy.savingQuarantine));

    for (final label in ['Save a copy', 'Delete it']) {
      expect(tester.widget<TextButton>(_button(label)).onPressed, isNull, reason: label);
    }
  });

  testWidgets('text scale 2.0', (tester) async {
    final (bloc, _) = dataBlocAt(const DataState(quarantineCopy: QuarantineCopy.saved));
    await pumpAtTextScale(
      tester,
      dataHost(
        const QuarantineNotice(),
        data: bloc,
        record: recordBlocAt(quarantine: QuarantineReason.malformed, quarantineKept: true),
      ),
      scale: 2.0,
    );

    expect(tester.takeException(), isNull);
    for (final label in ['Save a copy', 'Delete it']) {
      await tester.ensureVisible(_button(label));
      await tester.pump();
      expectHittable(tester, _button(label));
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await pumpNotice(
      tester,
      reason: QuarantineReason.malformed,
      state: const DataState(quarantineCopy: QuarantineCopy.saved),
      platform: defaultTargetPlatform,
    );

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
