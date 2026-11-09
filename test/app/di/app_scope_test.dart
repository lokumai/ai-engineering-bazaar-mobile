import 'package:ai_engineering_bazaar/app/di/app_scope.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/content_fixture.dart';

/// Fixture dependencies whose content repository is [repository].
final class _ContentDependencies extends FixtureAppDependencies {
  const _ContentDependencies(this.repository);

  final MockContentRepository repository;

  @override
  IContentRepository createContentRepository() => repository;
}

/// Fixture dependencies whose record repository is [repository].
final class _RecordDependencies extends FixtureAppDependencies {
  const _RecordDependencies(this.repository);

  final MockRecordRepository repository;

  @override
  IRecordRepository createRecordRepository() => repository;
}

const _emptyReady = RecordReady(
  record: RecordData.empty,
  writeState: WriteSaved(),
  quarantine: null,
  quarantineKept: false,
  launchReadFailed: false,
  undo: null,
);

void main() {
  testWidgets('provides the AppConfig of its dependencies', (tester) async {
    late AppConfig config;
    await tester.pumpWidget(
      AppScope(
        dependencies: const FixtureAppDependencies(),
        child: Builder(
          builder: (context) {
            config = context.read<AppConfig>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(config.environment, Environment.test);
    expect(config.contentBaseUrl, testContentBaseUrl);
  });

  testWidgets('provides the content repository and starts ContentBloc without a reader', (tester) async {
    final mock = readyContentRepository();
    late BuildContext context;
    await tester.pumpWidget(
      AppScope(
        dependencies: _ContentDependencies(mock),
        child: Builder(
          builder: (built) {
            context = built;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    verify(() => mock.open()).called(1);
    verify(() => mock.refresh()).called(1);
    expect(identical(context.read<IContentRepository>(), mock), isTrue);
    expect(context.read<ContentBloc>().state, isA<ContentReady>());
  });

  testWidgets('provides the record repository and starts RecordBloc without a reader', (tester) async {
    final mock = readyRecordRepository();
    late BuildContext captured;
    await tester.pumpWidget(
      AppScope(
        dependencies: _RecordDependencies(mock),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    verify(() => mock.load()).called(1);
    expect(identical(captured.read<IRecordRepository>(), mock), isTrue);
    expect(captured.read<RecordBloc>().state, _emptyReady);
  });

  testWidgets('FixtureAppDependencies starts the record empty without touching files', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      AppScope(
        dependencies: const FixtureAppDependencies(),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    expect(captured.read<RecordBloc>().state, _emptyReady);
  });

  testWidgets('AppScope provides the track and the web links', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      AppScope(
        dependencies: const FixtureAppDependencies(),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured.read<TrackCubit>().state, Track.engineers);
    expect(captured.read<WebLinks>().contentBaseUrl, testContentBaseUrl);
  });
}
