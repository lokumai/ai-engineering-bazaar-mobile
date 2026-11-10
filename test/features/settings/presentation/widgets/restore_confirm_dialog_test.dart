@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/restore_confirm_dialog.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/accessibility.dart';
import '../data_host.dart';

void main() {
  Future<Future<bool>> open(
    WidgetTester tester,
    Tally local, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    final (bloc, _) = dataBlocAt();
    await pumpDataHost(tester, const SizedBox.shrink(), data: bloc, platform: platform);
    final answer = showRestoreConfirmDialog(hostContext(tester), local);
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('asks with the local tally', (tester) async {
    await open(tester, const Tally(sheets: 2));

    expect(find.text('Replace the progress on this device?'), findsOneWidget);
    expect(find.text('On this device now:'), findsOneWidget);
    expect(find.text('2 module states'), findsOneWidget);
    expect(find.text('Restoring replaces it with the progress in the file.'), findsOneWidget);
    for (final word in ['Cancel', 'Yes', 'No']) {
      expect(find.text(word), findsNothing);
    }
  });

  testWidgets('one state reads in the singular, none as nothing recorded', (tester) async {
    await open(tester, const Tally(sheets: 1));
    expect(find.text('1 module state'), findsOneWidget);
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();

    await open(tester, const Tally(sheets: 0));
    expect(find.text('NOTHING RECORDED ON THIS DEVICE'), findsOneWidget);
  });

  testWidgets('Replace answers true and Keep my data false', (tester) async {
    final replaced = await open(tester, const Tally(sheets: 2));
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(await replaced, isTrue);
    expect(find.byType(Dialog), findsNothing);

    final kept = await open(tester, const Tally(sheets: 2));
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    expect(await kept, isFalse);
  });

  testWidgets('a tap outside the dialog keeps the data', (tester) async {
    final answer = await open(tester, const Tally(sheets: 2));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
  });

  testWidgets('text scale 2.0', (tester) async {
    final (bloc, _) = dataBlocAt();
    await pumpAtTextScale(tester, dataHost(const SizedBox.shrink(), data: bloc), scale: 2.0);
    showRestoreConfirmDialog(hostContext(tester), const Tally(sheets: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final label in ['Replace', 'Keep my data']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expectHittable(tester, find.text(label));
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await open(tester, const Tally(sheets: 2), platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
