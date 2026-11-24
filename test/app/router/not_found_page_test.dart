@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/accessibility.dart';
import '../../support/bazaar_app_harness.dart';
import '../../support/content_fixture.dart';
import '../../support/url_launcher_stub.dart';

const _title = 'No such module';
const _message = 'This address is not a module in the curriculum. The catalog lists every one that is.';

Finder _button(String label) => find.descendant(of: find.byType(NotFoundView), matching: find.text(label));

GoRouter _routerAtNope() {
  final router = const AppRouterFactory(initialLocation: '/nope').create();
  addTearDown(router.dispose);
  return router;
}

void main() {
  testWidgets('says the address is not a module', (tester) async {
    await tester.pumpWidget(bazaarTestApp(router: _routerAtNope()));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_message), findsOneWidget);
  });

  testWidgets('Catalog goes to the catalog root', (tester) async {
    final router = _routerAtNope();
    await tester.pumpWidget(bazaarTestApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(_button('Catalog'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/sheets');
  });

  // Review 11, features 2: it always went to the For Engineers catalog, which switched a For Everyone reader's track.
  testWidgets("Catalog keeps a For Everyone reader in their track's catalog", (tester) async {
    final router = const AppRouterFactory(initialLocation: '/everyone/courses/alpha/nonexistent').create();
    addTearDown(router.dispose);
    final track = TrackCubit();
    addTearDown(track.close);
    await tester.pumpWidget(bazaarTestApp(router: router, track: track));
    await tester.pumpAndSettle();
    expect(track.state, Track.everyone);

    await tester.tap(_button('Catalog'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/everyone/sheets');
    expect(track.state, Track.everyone);
  });

  testWidgets('Open on the web opens the site', (tester) async {
    final calls = stubOpeningUrlLauncher(canLaunch: true);
    await tester.pumpWidget(bazaarTestApp(router: _routerAtNope()));
    await tester.pumpAndSettle();

    await tester.tap(_button('Open on the web'));
    await tester.pumpAndSettle();

    expect(calls.launchedUrls, [testContentBaseUrl]);
  });

  testWidgets('text scale 2.0', (tester) async {
    await pumpAtTextScale(tester, bazaarTestApp(router: _routerAtNope()), scale: 2.0);

    expect(tester.takeException(), isNull);
    // The view scrolls; at this scale the buttons start below the fold.
    for (final label in ['Catalog', 'Open on the web']) {
      await tester.ensureVisible(_button(label));
      await tester.pump();
      expectHittable(tester, _button(label));
    }
  });

  testWidgets('accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(bazaarTestApp(platform: defaultTargetPlatform, router: _routerAtNope()));
    await tester.pumpAndSettle();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
