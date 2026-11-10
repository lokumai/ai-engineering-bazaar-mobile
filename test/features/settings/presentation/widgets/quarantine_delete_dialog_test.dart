@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/quarantine_delete_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/accessibility.dart';
import '../progress_host.dart';

void main() {
  Future<Future<bool>> open(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android}) async {
    final (bloc, _) = dataBlocAt();
    await pumpProgressHost(tester, const SizedBox.shrink(), data: bloc, platform: platform);
    final answer = showQuarantineDeleteDialog(hostContext(tester));
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('says what deleting does', (tester) async {
    await open(tester);

    expect(find.text('Delete the set-aside record?'), findsOneWidget);
    expect(find.text('This version of the app cannot read it. Deleting it cannot be undone.'), findsOneWidget);
    for (final word in ['Cancel', 'Yes', 'No']) {
      expect(find.text(word), findsNothing);
    }
  });

  testWidgets('Delete answers true and Keep it false', (tester) async {
    final deleted = await open(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await deleted, isTrue);
    expect(find.byType(Dialog), findsNothing);

    final kept = await open(tester);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(await kept, isFalse);
  });

  testWidgets('a tap outside the dialog keeps it', (tester) async {
    final answer = await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
  });

  testWidgets('text scale 2.0', (tester) async {
    final (bloc, _) = dataBlocAt();
    await pumpAtTextScale(tester, progressHost(const SizedBox.shrink(), data: bloc), scale: 2.0);
    showQuarantineDeleteDialog(hostContext(tester));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final label in ['Delete', 'Keep it']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expectHittable(tester, find.text(label));
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await open(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
