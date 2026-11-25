@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/website_section.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/infrastructure/transfer/deflate_transfer_packer.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/content_fixture.dart';
import '../data_host.dart';

/// A share sheet that keeps what it was given, shown unless [shows] is false.
final class _Sheet implements IShareSheet {
  _Sheet({this.shows = true});

  final bool shows;
  final shared = <String>[];

  @override
  Future<bool> share(String text) async {
    shared.add(text);
    return shows;
  }
}

/// A scanner that answers [outcome], or none when it is not [available].
final class _Scanner implements ICodeScanner {
  _Scanner(this.outcome, {this.isAvailable = true});

  final ScanOutcome outcome;
  final bool isAvailable;
  final titles = <String>[];
  final cancels = <String>[];

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<ScanOutcome> scan(String title, {required String cancel}) async {
    titles.add(title);
    cancels.add(cancel);
    return outcome;
  }
}

/// A scanner whose scan answers when [answer] completes.
final class _Waiting implements ICodeScanner {
  _Waiting(this.answer);

  final Completer<ScanOutcome> answer;

  @override
  Future<bool> available() async => true;

  @override
  Future<ScanOutcome> scan(String title, {required String cancel}) => answer.future;
}

final _completed = signOff(RecordData.empty, 'alpha/first', 'a1b2c3d', '2026-11-02T09:15:30.123Z');

/// The section on Settings' place in a router whose transfer page names the payload it was given.
Future<void> _pump(
  WidgetTester tester, {
  RecordBloc? record,
  IShareSheet? sheet,
  ICodeScanner? scanner,
  ITransferPacker packer = const DeflateTransferPacker(),
  Locale locale = const Locale('en'),
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(padding: EdgeInsets.all(16), child: WebsiteSection()),
        ),
      ),
      GoRoute(path: BazaarPaths.transfer, builder: (_, state) => Text('transfer ${state.extra}')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WebLinks>.value(value: const WebLinks(testContentBaseUrl)),
        RepositoryProvider<IShareSheet>.value(value: sheet ?? const NoShareSheet()),
        RepositoryProvider<ICodeScanner>.value(value: scanner ?? const NoCodeScanner()),
        RepositoryProvider<ITransferPacker>.value(value: packer),
      ],
      child: BlocProvider<RecordBloc>.value(
        value: record ?? recordBlocAt(),
        child: MaterialApp.router(
          routerConfig: router,
          theme: bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: locale,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A packer whose payload is one character longer than the website reads.
final class _LongPacker implements ITransferPacker {
  const _LongPacker();

  @override
  String pack(String text) => 'a' * (transferMaxPayload + 1);

  @override
  String? unpack(String payload) => null;
}

String _transferLink(String payload) => '${testContentBaseUrl}transfer/#t=$payload';

void main() {
  group('from the website to this phone (plan 17.5)', () {
    testWidgets('comes first and says where the website keeps its code', (tester) async {
      await _pump(tester);

      final from = tester.getTopLeft(find.text('From the website to this device')).dy;
      final to = tester.getTopLeft(find.text('From this device to the website')).dy;
      expect(from, lessThan(to));
      expect(find.textContaining('open Progress at the top and choose Move to the app'), findsOneWidget);
    });

    testWidgets('a phone that cannot scan in the app shows no button', (tester) async {
      await _pump(tester, scanner: _Scanner(const ScanCancelled(), isAvailable: false));

      expect(find.byKey(const ValueKey('settings-scan-code')), findsNothing);
    });

    testWidgets('a progress link read by the camera opens the transfer page with its payload', (tester) async {
      final scanner = _Scanner(ScanRead(_transferLink('abc')));
      await _pump(tester, scanner: scanner);

      await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
      await tester.pumpAndSettle();

      expect(scanner.titles, ["Scan the website's code"]);
      expect(scanner.cancels, ['Cancel']);
      expect(find.text('transfer abc'), findsOneWidget);
    });

    // Review 8, finding 17: iOS drew its own Cancel in the phone's language, under the app's title in the app's.
    testWidgets("the camera's Cancel is in the app's language", (tester) async {
      final scanner = _Scanner(const ScanCancelled());
      await _pump(tester, scanner: scanner, locale: const Locale('tr'));

      await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
      await tester.pumpAndSettle();

      expect(scanner.cancels, ['İptal']);
    });

    // The owner's iPhone, 2026-11-19: the site's code from a test server on the computer carries its address.
    testWidgets('a progress link from a copy of the site, over http with a port, is read too', (tester) async {
      await _pump(tester, scanner: _Scanner(const ScanRead('http://192.168.1.107:3111/transfer/#t=lan')));

      await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
      await tester.pumpAndSettle();

      expect(find.text('transfer lan'), findsOneWidget);
    });

    testWidgets("the app's own scheme is read too", (tester) async {
      await _pump(tester, scanner: _Scanner(const ScanRead('aibazaar://transfer#t=xyz')));

      await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
      await tester.pumpAndSettle();

      expect(find.text('transfer xyz'), findsOneWidget);
    });

    for (final (name, outcome, line) in [
      ('another code', const ScanRead('https://example.com/'), 'That code is not a progress link from the website.'),
      (
        "another site's page that is not a transfer",
        const ScanRead('http://192.168.1.107:3111/courses/'),
        'That code is not a progress link from the website.',
      ),
      (
        'a page of the site that is not a transfer',
        ScanRead('${testContentBaseUrl}courses/'),
        'That code is not a progress link from the website.',
      ),
      (
        'the camera not allowed',
        const ScanDenied(),
        "The app may not use the camera. Allow it in the device's Settings, or scan the code with the Camera app.",
      ),
      (
        'the camera not opened',
        const ScanFailed(),
        'The camera did not open. Scan the code with the Camera app instead.',
      ),
    ]) {
      testWidgets('$name is said, and no page opens', (tester) async {
        await _pump(tester, scanner: _Scanner(outcome));

        await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
        await tester.pumpAndSettle();

        expect(find.text(line), findsOneWidget);
        expect(find.textContaining('transfer '), findsNothing);
      });
    }

    // Review 3, finding 8: Play services may fetch Google's scanner first, a wait with the button off and no word.
    testWidgets('while the scanner opens it says so, and the line goes once the scan ends', (tester) async {
      final answer = Completer<ScanOutcome>();
      await _pump(tester, scanner: _Waiting(answer));

      await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
      await tester.pump();
      expect(find.text('Opening the scanner. The first time, this can take a minute.'), findsOneWidget);

      answer.complete(const ScanCancelled());
      await tester.pumpAndSettle();
      expect(find.textContaining('Opening the scanner'), findsNothing);
    });

    testWidgets('going back from the camera says nothing', (tester) async {
      await _pump(tester, scanner: _Scanner(const ScanCancelled()));

      await tester.tap(find.byKey(const ValueKey('settings-scan-code')));
      await tester.pumpAndSettle();

      expect(find.byType(WebsiteSection), findsOneWidget);
      expect(find.textContaining('code is not'), findsNothing);
    });

    testWidgets('reads in Turkish and Persian', (tester) async {
      await _pump(tester, scanner: _Scanner(const ScanCancelled()), locale: const Locale('tr'));
      expect(find.text('Web sitesinden bu cihaza'), findsOneWidget);
      expect(find.text('Kodu okut'), findsOneWidget);

      await _pump(tester, scanner: _Scanner(const ScanCancelled()), locale: const Locale('fa'));
      expect(find.text('از وب\u200cسایت به این دستگاه'), findsOneWidget);
      expect(find.text('اسکن کد'), findsOneWidget);
    });
  });

  group('from this phone to the website (plan 17.1)', () {
    testWidgets('Send to the website shares a transfer link to the site that carries the progress', (tester) async {
      final sheet = _Sheet();
      await _pump(
        tester,
        record: recordBlocAt(record: _completed),
        sheet: sheet,
        scanner: _Scanner(const ScanCancelled()),
      );

      await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
      await tester.pump();

      final link = Uri.parse(sheet.shared.single);
      expect(link.toString(), startsWith('${testContentBaseUrl}transfer/#t='));
      final payload = (SiteLink.parse(link, Uri.parse(testContentBaseUrl))! as SiteTransfer).payload;
      final progress = decodeTransfer(const DeflateTransferPacker().unpack(payload)!)!;
      expect(progress.engineers['alpha/first']!.signedOff, '2026-11-02T09:15:30.123Z');
      expect(progress.completed(Track.engineers), 1);
      await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
    });

    // Review 12, R1: after a failed launch read it said there was nothing to send, or sent only what was done since.
    testWidgets('a record that could not be read at launch is not sent: the button is off', (tester) async {
      final sheet = _Sheet();
      await _pump(
        tester,
        record: recordBlocAt(record: _completed, writeState: const WriteBlocked(), launchReadFailed: true),
        sheet: sheet,
      );

      final button = find.byKey(const ValueKey('settings-send-to-website'));
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(sheet.shared, isEmpty);
    });

    testWidgets('with nothing to send it says so and opens no sheet', (tester) async {
      final sheet = _Sheet();
      await _pump(tester, sheet: sheet);

      await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
      await tester.pump();

      expect(sheet.shared, isEmpty);
      expect(find.text('Nothing to send yet: no module is completed and no checklist item is ticked.'), findsOneWidget);
    });

    // Review 7, finding 14: a link longer than the website reads was shared all the same.
    testWidgets('progress too long for the link the website reads is said, and opens no sheet', (tester) async {
      final sheet = _Sheet();
      await _pump(
        tester,
        record: recordBlocAt(record: _completed),
        sheet: sheet,
        packer: const _LongPacker(),
      );

      await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
      await tester.pump();

      expect(sheet.shared, isEmpty);
      expect(find.text('Your progress is too long to fit in a link.'), findsOneWidget);
    });

    testWidgets('a sheet that cannot be shown is said', (tester) async {
      await _pump(
        tester,
        record: recordBlocAt(record: _completed),
        sheet: _Sheet(shows: false),
      );

      await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
      await tester.pump();

      expect(find.text('The share menu did not open.'), findsOneWidget);
    });
  });
}
