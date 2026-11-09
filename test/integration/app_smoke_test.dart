@Tags(['widget'])
library;

import 'dart:io';

import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/catalog_page.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/bazaar_app_harness.dart';
import '../support/content_builders.dart';
import '../support/content_fixture.dart';

/// The fixture dependencies over real files in [dir]: the content store opens the synthetic bundle with its cache in
/// `<dir>/cache` and a refresh that fails offline, and the record lives in `<dir>/record/`.
class _SmokeDependencies extends FixtureAppDependencies {
  const _SmokeDependencies(this.dir);

  final Directory dir;

  @override
  IContentRepository createContentRepository() => FileContentRepository(
    bundled: BundledContent(bundle: FixtureAssetBundle()),
    cacheDirectory: () async => Directory('${dir.path}/cache')..createSync(recursive: true),
    http: ContentHttp(client: MockClient((_) async => http.Response('', 500)), contentBaseUrl: testContentBaseUrl),
  );

  @override
  IRecordRepository createRecordRepository() => FileRecordRepository(baseDirectory: () async => dir);
}

/// Lets real file I/O finish, which does not complete under the fake clock: a short real wait and a frame, repeated
/// until [done] holds, failing after [rounds] rounds.
Future<void> _drain(WidgetTester tester, bool Function() done, {required String what, int rounds = 100}) async {
  for (var round = 0; round < rounds; round++) {
    if (done()) return;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  if (done()) return;
  throw TestFailure('$what did not happen after $rounds rounds');
}

/// End-to-end smoke: boots the whole app over the fixture dependencies (the fixture content, no network), and lands on
/// the catalog inside the shell once the content and the record are ready. There is no sign-in. The second test
/// completes a module over real files and reads it back after a restart.
void main() {
  testWidgets('cold start shows the catalog with no sign-in', (tester) async {
    await tester.pumpWidget(const App(dependencies: FixtureAppDependencies()));
    await pumpUntilFound(tester, find.byType(CatalogPage));

    expect(find.byType(CatalogPage), findsOneWidget);
    expect(find.byType(BazaarShell), findsOneWidget);
  });

  testWidgets(
    'completing a module survives a restart',
    (tester) => withClock(Clock.fixed(DateTime.utc(2026, 11, 9, 10)), () async {
      final dir = Directory.systemTemp.createTempSync('bazaar_smoke_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final title = ContentParser.parseIndex(File('$contentFixtureBundle/index.json').readAsStringSync())
          .module('alpha/first')!
          .tracks[Track.engineers]!
          .title;
      final recordFile = File('${dir.path}/record/record.json');
      final completion = find.byKey(const Key('reader-completion'));

      Future<void> openFirst() async {
        await _drain(tester, () => find.byType(CatalogPage).evaluate().isNotEmpty, what: 'the catalog');
        await tester.tap(find.text(title));
        await tester.pump();
        await _drain(tester, () => completion.evaluate().isNotEmpty, what: 'the reader of $title');
        await settleContent(tester);
      }

      await tester.pumpWidget(App(dependencies: _SmokeDependencies(dir)));
      await openFirst();
      await tester.ensureVisible(completion);
      await tester.tap(completion);
      await tester.pump();
      await _drain(tester, recordFile.existsSync, what: 'the record write');
      await tester.pump();

      expect(find.text('Completed 9 Nov 2026'), findsOneWidget);
      expect(recordFile.readAsStringSync(), contains('"signedOff":"2026-11-09T10:00:00.000Z"'));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(App(dependencies: _SmokeDependencies(dir)));
      await openFirst();

      expect(tester.widget<CheckboxListTile>(completion).value, isTrue);
      expect(find.text('Completed 9 Nov 2026'), findsOneWidget);
      final state = tester.element(find.byType(ModuleReaderView)).read<RecordBloc>().state;
      expect(state, isA<RecordReady>());
      final record = (state as RecordReady).record;
      expect(record.signedMap(Track.everyone), isEmpty);
      expect(record.signedOff('alpha/first', Track.engineers), '2026-11-09T10:00:00.000Z');
    }),
  );
}
