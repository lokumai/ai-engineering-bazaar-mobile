import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/content_fixture.dart';
import '../../../support/content_refresh_cases.dart';

void main() {
  final index = ContentParser.parseIndex(File('$contentFixtureBundle/index.json').readAsStringSync());
  final newer = ContentParser.parseIndex(utf8.decode(publishedSite()['api/v1/index.json']!));

  late MockContentRepository repository;

  setUp(() => repository = MockContentRepository());

  ContentReady ready(RefreshStatus refresh, {BundleIndex? at, ContentOrigin? origin, ContentNotice? notice}) =>
      ContentReady(index: at ?? index, origin: origin ?? ContentOrigin.bundled, notice: notice, refresh: refresh);

  void opens({ContentNotice? notice}) =>
      when(() => repository.open())
          .thenAnswer((_) async => ContentOpening(index: index, origin: ContentOrigin.bundled, notice: notice));

  test('starts loading', () => expect(ContentBloc(repository: repository).state, const ContentLoading()));

  blocTest<ContentBloc, ContentState>(
    'starts, opens, then refreshes once',
    setUp: () {
      opens();
      when(() => repository.refresh()).thenAnswer((_) async => const ContentUpToDate());
    },
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    expect: () => [ready(const RefreshIdle()), ready(const RefreshChecking()), ready(const RefreshUpToDate())],
    verify: (_) => verify(() => repository.refresh()).called(1),
  );

  blocTest<ContentBloc, ContentState>(
    'a bundled index that fails is ContentBroken and never refreshes',
    setUp: () => when(() => repository.open()).thenThrow(const ContentFormatException('api/v1/index.json', 'root')),
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    expect: () => [const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable)],
    verify: (_) => verifyNever(() => repository.refresh()),
  );

  blocTest<ContentBloc, ContentState>(
    'a bundled object the app does not hold is ContentBroken',
    setUp: () => when(() => repository.open()).thenThrow(const ContentMissingException('api/v1/index.json')),
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    expect: () => [const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable)],
    verify: (_) => verifyNever(() => repository.refresh()),
  );

  blocTest<ContentBloc, ContentState>(
    'a storage error at open is ContentBroken(storage)',
    setUp: () => when(() => repository.open()).thenThrow(const FileSystemException('x')),
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    expect: () => [const ContentBroken(code: ContentErrorCode.storage)],
    verify: (_) => verifyNever(() => repository.refresh()),
  );

  blocTest<ContentBloc, ContentState>(
    'an update replaces the index and keeps the notice',
    setUp: () {
      opens(notice: ContentNotice.cacheDiscarded);
      when(() => repository.refresh()).thenAnswer((_) async => ContentUpdated(index: newer));
    },
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    expect: () => [
      ready(const RefreshIdle(), notice: ContentNotice.cacheDiscarded),
      ready(const RefreshChecking(), notice: ContentNotice.cacheDiscarded),
      ready(const RefreshUpdated(), at: newer, origin: ContentOrigin.downloaded, notice: ContentNotice.cacheDiscarded),
    ],
  );

  blocTest<ContentBloc, ContentState>(
    'a failed refresh keeps the current content',
    setUp: () {
      opens();
      when(() => repository.refresh())
          .thenAnswer((_) async => const ContentRefreshFailed(code: ContentErrorCode.network));
    },
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    skip: 2,
    expect: () => [ready(const RefreshFailed(ContentErrorCode.network))],
  );

  blocTest<ContentBloc, ContentState>(
    'NeedsAppUpdate',
    setUp: () {
      opens();
      when(() => repository.refresh()).thenAnswer((_) async => const ContentNeedsAppUpdate());
    },
    build: () => ContentBloc(repository: repository),
    act: (bloc) => bloc.add(const ContentStarted()),
    skip: 2,
    expect: () => [ready(const RefreshNeedsAppUpdate())],
  );

  blocTest<ContentBloc, ContentState>(
    'a refresh request before ready is ignored',
    build: () => ContentBloc(repository: repository),
    seed: () => const ContentLoading(),
    act: (bloc) => bloc.add(const ContentRefreshRequested()),
    expect: () => <ContentState>[],
    verify: (_) => verifyNever(() => repository.refresh()),
  );

  final pending = Completer<RefreshOutcome>();
  blocTest<ContentBloc, ContentState>(
    'refresh requests during a refresh are dropped',
    setUp: () => when(() => repository.refresh()).thenAnswer((_) => pending.future),
    build: () => ContentBloc(repository: repository),
    seed: () => ready(const RefreshIdle()),
    act: (bloc) async {
      bloc
        ..add(const ContentRefreshRequested())
        ..add(const ContentRefreshRequested());
      await Future<void>.delayed(Duration.zero);
      pending.complete(const ContentUpToDate());
    },
    expect: () => [ready(const RefreshChecking()), ready(const RefreshUpToDate())],
    verify: (_) => verify(() => repository.refresh()).called(1),
  );

  blocTest<ContentBloc, ContentState>(
    'a refresh after a finished one runs again',
    setUp: () => when(() => repository.refresh()).thenAnswer((_) async => const ContentUpToDate()),
    build: () => ContentBloc(repository: repository),
    seed: () => ready(const RefreshUpToDate()),
    act: (bloc) async {
      bloc.add(const ContentRefreshRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ContentRefreshRequested());
    },
    expect: () => [
      ready(const RefreshChecking()),
      ready(const RefreshUpToDate()),
      ready(const RefreshChecking()),
      ready(const RefreshUpToDate()),
    ],
    verify: (_) => verify(() => repository.refresh()).called(2),
  );

  // 4.2 #9 and spec 3.11: every failing refresh step, over the real repository.
  group('over the file repository', () {
    late Directory cacheRoot;

    setUp(() => cacheRoot = Directory.systemTemp.createTempSync('content_cache'));
    tearDown(() => cacheRoot.deleteSync(recursive: true));

    for (final failure in refreshFailureCases) {
      blocTest<ContentBloc, ContentState>(
        'a refresh that fails at ${failure.step} keeps the bundled content',
        build: () {
          final handler = failure.handler(publishedSite());
          var arranged = false;
          return ContentBloc(
            repository: FileContentRepository(
              bundled: BundledContent(bundle: FixtureAssetBundle()),
              cacheDirectory: () async => cacheRoot,
              // The first request comes after open(), which is when a case arranges the cache root.
              http: ContentHttp(
                client: MockClient((request) {
                  if (!arranged) {
                    arranged = true;
                    failure.arrange?.call(cacheRoot);
                  }
                  return handler(request);
                }),
                contentBaseUrl: testContentBaseUrl,
              ),
            ),
          );
        },
        act: (bloc) => bloc.add(const ContentStarted()),
        wait: const Duration(milliseconds: 100),
        expect: () => [ready(const RefreshIdle()), ready(const RefreshChecking()), ready(RefreshFailed(failure.code))],
      );
    }
  });
}
