@Tags(['widget'])
library;

import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/router/home_placeholder_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end smoke: boots the whole app with App's default dependencies, as main_local does, and lands on the home
/// page. There is no sign-in. Task 10.6 extends it to the reader.
void main() {
  testWidgets('cold start shows the home page with no sign-in', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(HomePlaceholderPage), findsOneWidget);
  });
}
