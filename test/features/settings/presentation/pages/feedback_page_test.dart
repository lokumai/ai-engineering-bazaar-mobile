@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/feedback_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required bool crashReports,
  MockFeedbackSender? sender,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final router = AppRouterFactory(initialLocation: '/settings', crashReports: crashReports).create();
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, platform: platform, feedbackSender: sender));
  await tester.pumpAndSettle();
}

Future<void> _openPage(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Report a problem'), 200);
  await tester.tap(find.text('Report a problem'));
  await tester.pumpAndSettle();
}

void main() {
  for (final crashReports in [false, true]) {
    testWidgets('Settings ${crashReports ? 'shows' : 'hides'} Report a problem when the build '
        '${crashReports ? 'sends' : 'sends no'} crash reports', (tester) async {
      await _pumpSettings(tester, crashReports: crashReports);

      expect(find.text('Report a problem', skipOffstage: false), crashReports ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('sends what the reader wrote and says it was sent', (tester) async {
    final sender = MockFeedbackSender();
    when(() => sender.send(any())).thenAnswer((_) async {});
    await _pumpSettings(tester, crashReports: true, sender: sender);
    await _openPage(tester);

    expect(find.byType(FeedbackPage), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send')).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'The quiz froze');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    verify(() => sender.send('The quiz froze')).called(1);
    expect(find.text('The report is sent.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('keeps the text and says the report was not sent when sending fails', (tester) async {
    final sender = MockFeedbackSender();
    when(() => sender.send(any())).thenThrow(StateError('off'));
    await _pumpSettings(tester, crashReports: true, sender: sender);
    await _openPage(tester);

    await tester.enterText(find.byType(TextField), 'The quiz froze');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    expect(find.text('The report was not sent. Try again later.'), findsOneWidget);
    expect(find.text('The quiz froze'), findsOneWidget);
  });

  // iOS has no back key to close the keyboard: a tap outside the field or a drag of the page closes it, as in the
  // catalog's search, and the field keeps a few lines so it fits above the keyboard (the owner, 2026-11-13).
  testWidgets('a tap outside the field or a drag of the page closes the keyboard', (tester) async {
    // A phone's height with the keyboard up, so the page scrolls.
    tester.view.physicalSize = const Size(390, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpSettings(tester, crashReports: true, platform: TargetPlatform.iOS);
    await _openPage(tester);

    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.descendant(of: find.byType(FeedbackPage), matching: find.byType(SectionRule)));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse, reason: 'a tap outside the field');

    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.drag(find.byType(FeedbackPage), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse, reason: 'a drag of the page');
  });

  // The shell's scaffold already makes room for the keyboard; the page's own must not make it again, or the page
  // shrinks by the keyboard twice and the field is cut in half above an empty band (the owner, 2026-11-13).
  testWidgets('with the keyboard up, the page ends at the keyboard, not a keyboard higher', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await _pumpSettings(tester, crashReports: true, platform: TargetPlatform.iOS);
    await _openPage(tester);

    final page = tester.getRect(
      find.descendant(of: find.byType(FeedbackPage), matching: find.byType(Scrollable)).first,
    );
    expect(page.bottom, 844 - 300);
  });

  testWidgets('the field grows to six lines at most', (tester) async {
    await _pumpSettings(tester, crashReports: true);
    await _openPage(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 4);
    expect(field.maxLines, 6);
  });

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pumpSettings(tester, crashReports: true, platform: defaultTargetPlatform);
    await _openPage(tester);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
