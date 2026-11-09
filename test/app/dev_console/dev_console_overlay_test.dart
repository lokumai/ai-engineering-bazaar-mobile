@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/dev_console/dev_console_overlay.dart';
import 'package:flutter_bloc_advance/app/dev_console/dev_console_store.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(DevConsoleStore.instance.clearAll);
  tearDown(DevConsoleStore.instance.clearAll);

  // A host page that opens the developer console on its first tab. The console's colours come from the app theme.
  Future<void> openConsole(WidgetTester tester, {required Size size, required double textScale}) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => DevConsoleOverlay.show(context),
                child: const SizedBox.square(dimension: 48),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light(), routerConfig: router));
    await tester.tap(find.byType(TextButton));
    // The sheet's animation is pumped through rather than settled.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  for (final textScale in const [1.0, 1.3]) {
    for (final size in const [Size(320, 568), Size(360, 640), Size(375, 667)]) {
      final phone = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('the console fits a $phone phone at text scale $textScale', (tester) async {
        await openConsole(tester, size: size, textScale: textScale);
        expect(tester.takeException(), isNull, reason: 'title bar, tab bar and the BLoC tab');
        expect(find.text('Network'), findsNothing);
        expect(find.text('Env'), findsNothing);
        expect(find.text('Storage'), findsNothing);

        for (final (index, tab) in const ['Time Travel'].indexed) {
          await tester.tap(find.text(tab));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, index + 1, reason: '$tab is open');
          expect(tester.takeException(), isNull, reason: 'the $tab tab');
        }
      });
    }
  }
}
