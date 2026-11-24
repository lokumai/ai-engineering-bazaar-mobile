@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/catalog_fixture_index.dart';
import '../../../support/content_builders.dart';

void main() {
  // Review 11, features 1: a site link opened before the start refresh said "not a module", and kept saying it after
  // the refresh brought the module in; the reader keeps the index it opened with.
  testWidgets('a module the content did not hold opens when newer content brings it', (tester) async {
    final full = catalogFixtureIndex(contentVersion: 'a' * 64);
    final old = BundleIndex(
      contentVersion: 'b' * 64,
      publishedAt: full.publishedAt,
      publishedAtInstant: full.publishedAtInstant,
      tracks: full.tracks,
      diagramFont: full.diagramFont,
      diagramThemes: full.diagramThemes,
      levels: full.levels,
      modules: [
        for (final module in full.modules)
          if (module.key != 'beta/fourth') module,
      ],
      moved: full.moved,
      files: full.files,
      images: full.images,
    );
    final content = MockContentBloc();
    final later = StreamController<ContentState>();
    addTearDown(later.close);
    whenListen(
      content,
      later.stream,
      initialState: ContentReady(index: old, origin: ContentOrigin.bundled, notice: null, refresh: const RefreshIdle()),
    );
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => testDoc(key: 'beta/fourth', title: 'Fourth'));
    final router = const AppRouterFactory(initialLocation: '/courses/beta/fourth').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, content: content, repository: repository));
    await tester.pumpAndSettle();
    expect(find.textContaining('is not a module'), findsOneWidget);

    later.add(
      ContentReady(index: full, origin: ContentOrigin.downloaded, notice: null, refresh: const RefreshUpdated()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('is not a module'), findsNothing);
    expect(find.text('Fourth'), findsWidgets);
  });
}
