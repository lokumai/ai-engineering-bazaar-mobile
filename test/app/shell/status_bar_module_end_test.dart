@Tags(['widget'])
library;

/// The iOS status bar tap over the reader with a real module of the bundled course (plan 12.3): the owner found it did
/// not go back to the top at a module's end on the iPhone, though it did in the middle.

import 'package:ai_engineering_bazaar/app/router/app_router.dart';

import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/bazaar_app_harness.dart';

Future<void> _tapStatusBar(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.statusBar.name,
    SystemChannels.statusBar.codec.encodeMethodCall(const MethodCall('handleScrollToTop')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// The bundled course's index and a reader of its documents, as the app ships them.
(BundleIndex, MockContentRepository) _bundled() {
  final indexJson = File('assets/content/index.json').readAsStringSync();
  final index = ContentParser.parseIndex(indexJson);
  final files = (jsonDecode(indexJson) as Map<String, Object?>)['files']! as Map<String, Object?>;
  final repository = missingContentRepository();
  when(() => repository.readModuleDoc(any())).thenAnswer((invocation) async {
    final path = invocation.positionalArguments.single as String;
    final text = File('assets/content/objects/${files[path]}').readAsStringSync();
    return ContentParser.parseModuleDoc(text, index, path: path);
  });
  return (index, repository);
}

void main() {
  for (final end in [false, true]) {
    testWidgets(
      'the real RAG module goes back to its top on a status bar tap, ${end ? 'from its end' : 'from its middle'}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final (index, repository) = _bundled();
        final router = const AppRouterFactory().create();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          bazaarTestApp(
            router: router,
            content: readyContentBloc(index),
            record: readyRecordBloc(),
            repository: repository,
            platform: TargetPlatform.iOS,
          ),
        );
        await tester.pumpAndSettle();
        router.push(BazaarPaths.module(Track.engineers, 'fundamentals/rag'));
        await tester.pumpAndSettle();
        // The page's own scroll; the module's wide tables scroll sideways inside it.
        final module = find
            .byType(Scrollable)
            .evaluate()
            .map((e) => ((e as StatefulElement).state as ScrollableState).position)
            .singleWhere((position) => position.axis == Axis.vertical);
        expect(module.maxScrollExtent, greaterThan(10000), reason: 'the whole module, not a table');
        if (end) {
          module.jumpTo(module.maxScrollExtent - 300);
          await tester.pumpAndSettle();
          // The last stretch by hand, as a reader reaches the end: a fling past it, which bounces on iOS.
          await tester.flingFrom(const Offset(200, 400), const Offset(0, -1500), 3000);
          await tester.pumpAndSettle();
        } else {
          module.jumpTo(module.maxScrollExtent / 2);
          await tester.pumpAndSettle();
        }
        expect(module.pixels, end ? module.maxScrollExtent : greaterThan(0));

        await _tapStatusBar(tester);

        expect(module.pixels, 0);
      },
    );
  }
}
