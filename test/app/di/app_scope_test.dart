import 'package:ai_engineering_bazaar/app/di/app_scope.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
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
}
