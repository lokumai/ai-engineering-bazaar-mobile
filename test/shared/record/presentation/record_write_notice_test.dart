@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/presentation/record_write_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

const _quota = 'Not saved: this device has no space left. Back up to a file to keep it.';

void main() {
  late int backUps;

  setUp(() => backUps = 0);

  Future<void> pumpNotice(WidgetTester tester, WriteState writeState) =>
      pumpInTheme(tester, RecordWriteNotice(writeState: writeState, onBackUp: () => backUps++), Brightness.light);

  testWidgets('the write notice names the failure', (tester) async {
    await pumpNotice(tester, const WriteQuota());
    expect(find.text(_quota), findsOneWidget);

    await pumpNotice(tester, const WriteBlocked());
    expect(find.text('Not saved: the app could not write its file. Back up to a file to keep it.'), findsOneWidget);

    await pumpNotice(tester, const WriteTooLarge());
    expect(
      find.text('Not saved: the record is larger than the app will write. Back up to a file to keep it.'),
      findsOneWidget,
    );

    for (final state in const [WriteSaved(), WritePending()]) {
      await pumpNotice(tester, state);
      expect(find.byKey(const Key('write-failure')), findsNothing);
      expect(find.byType(Text), findsNothing);
    }
  });

  testWidgets('the notice is a live region and one tap target that backs up', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpNotice(tester, const WriteQuota());

    expect(
      tester.getSemantics(find.byKey(const Key('write-failure'))),
      isSemantics(isLiveRegion: true, isButton: true, hasTapAction: true, label: _quota),
    );
    expect(
      tester.getSize(find.byKey(const Key('write-failure'))).height,
      greaterThanOrEqualTo(minTapTarget(TargetPlatform.android)),
    );

    await tester.tap(find.textContaining('Back up to a file'));
    expect(backUps, 1);
    handle.dispose();
  });

  testWidgets('the notice text is onSurface with a fault edge', (tester) async {
    await pumpNotice(tester, const WriteBlocked());
    final colors = tester.element(find.byType(RecordWriteNotice)).bazaarColors;

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, colors.onSurface);
    expect(text.style?.fontSize, BazaarType.meta.size);

    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byKey(const Key('write-failure')), matching: find.byType(DecoratedBox)).first,
    );
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.left, BorderSide(width: 2, color: colors.fault));
    expect([border.top, border.right, border.bottom], everyElement(BorderSide.none));
  });
}
