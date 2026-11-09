import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/accessibility.dart';
import '../../../support/themed_app.dart';

void main() {
  CompletionDial dial({int done = 3, int total = 8}) => CompletionDial(
    done: done,
    total: total,
    color: const Color(0xff2f8c86),
    center: '$done/$total',
    semanticLabel: '$done of $total modules completed',
  );

  test('fills by done over total, clamped, and is empty with no total', () {
    expect(dial().fraction, 3 / 8);
    expect(dial(done: 9).fraction, 1);
    expect(dial(done: 0, total: 0).fraction, 0);
  });

  testWidgets('is one image named by its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(Center(child: dial())));

    expect(
      tester.getSemantics(find.byType(CompletionDial)),
      matchesSemantics(label: '3 of 8 modules completed', isImage: true),
    );
    handle.dispose();
  });

  testWidgets('grows with the text scale', (tester) async {
    await pumpAtTextScale(tester, themedApp(Center(child: dial())), scale: 1);
    final small = tester.getSize(find.byType(CompletionDial)).width;
    await pumpAtTextScale(tester, themedApp(Center(child: dial())), scale: 2);

    expect(tester.getSize(find.byType(CompletionDial)).width, small * 2);
  });

  test('repaints when what it draws changes', () {
    const painter = CompletionDialPainter(fraction: .5, color: Color(0xff000001), track: Color(0xff000002), ring: 5);
    expect(
      painter.shouldRepaint(
        const CompletionDialPainter(fraction: .5, color: Color(0xff000001), track: Color(0xff000002), ring: 5),
      ),
      isFalse,
    );
    expect(
      painter.shouldRepaint(
        const CompletionDialPainter(fraction: .6, color: Color(0xff000001), track: Color(0xff000002), ring: 5),
      ),
      isTrue,
    );
  });
}
