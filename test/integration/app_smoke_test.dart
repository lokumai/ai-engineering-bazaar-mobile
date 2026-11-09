@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/app/router/home_placeholder_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/content_fixture.dart';

/// End-to-end smoke: boots the whole app over the fixture dependencies (the fixture content, no network), and lands on
/// the home page. There is no sign-in. Task 10.6 extends it to the reader.
void main() {
  testWidgets('cold start shows the home page with no sign-in', (tester) async {
    await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePlaceholderPage), findsOneWidget);
  });
}
