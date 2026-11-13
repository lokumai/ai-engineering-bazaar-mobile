@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/feedback_page.dart';
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

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pumpSettings(tester, crashReports: true, platform: defaultTargetPlatform);
    await _openPage(tester);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
