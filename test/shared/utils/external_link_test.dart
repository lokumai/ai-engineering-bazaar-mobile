@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/utils/external_link.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/url_launcher_stub.dart';

void main() {
  const url = 'https://example.com/docs';

  Future<void> pumpLinkButton(WidgetTester tester, {Future<void> Function(BuildContext context)? open}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(
                  onPressed: () => open == null ? openExternalLink(context, Uri.parse(url)) : open(context),
                  child: const Text('Docs'),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('openExternalLink', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tries to open the link and names it in a message when ${failure.description}', (tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpLinkButton(tester);
        final l10n = S.of(tester.element(find.byType(TextButton)));

        final addedTexts = await expectTapShowsMessage(tester, find.byType(TextButton));
        expect(addedTexts, [l10n.error_link_open_failed(url)]);
        expect(calls.launchedUrls, [url]);
      });
    }

    for (final canLaunch in [true, false]) {
      testWidgets('opens the link and shows no message when canLaunchUrl answers $canLaunch', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpLinkButton(tester);

        await expectTapShowsNoMessage(tester, find.byType(TextButton));
        expect(calls.launchedUrls, [url]);
      });
    }
  });

  group('only the web, mail and the phone open (review G)', () {
    for (final link in ['file:///etc/hosts', 'intent://scan#Intent;end', 'javascript:alert(1)']) {
      testWidgets('$link is refused and named in a message', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: true);
        await pumpLinkButton(tester, open: (context) => openExternalLink(context, Uri.parse(link)));
        final l10n = S.of(tester.element(find.byType(TextButton)));

        expect(await expectTapShowsMessage(tester, find.byType(TextButton)), [l10n.error_link_open_failed(link)]);
        expect(calls.launchedUrls, isEmpty);
      });
    }

    testWidgets('a link that is not a URL says it did not open instead of throwing', (tester) async {
      const broken = 'https://[not a url';
      final calls = stubOpeningUrlLauncher(canLaunch: true);
      await pumpLinkButton(tester, open: (context) => openExternalUrl(context, broken));
      final l10n = S.of(tester.element(find.byType(TextButton)));

      expect(await expectTapShowsMessage(tester, find.byType(TextButton)), [l10n.error_link_open_failed(broken)]);
      expect(calls.launchedUrls, isEmpty);
    });

    for (final link in ['mailto:info@example.com', 'tel:+905550000000', 'http://example.com/']) {
      testWidgets('$link opens', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: true);
        await pumpLinkButton(tester, open: (context) => openExternalLink(context, Uri.parse(link)));

        await expectTapShowsNoMessage(tester, find.byType(TextButton));
        expect(calls.launchedUrls, [link]);
      });
    }
  });
}
