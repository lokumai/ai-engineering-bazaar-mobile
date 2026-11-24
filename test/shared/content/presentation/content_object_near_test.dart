import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';

/// Review 11, architecture 5: a module's figures were all read as it opened; one far below waits until it comes near.
void main() {
  testWidgets('an object far below the view is read only once it comes within a screen of it', (tester) async {
    final repository = MockContentRepository();
    when(() => repository.readObject(any())).thenAnswer((_) async => Uint8List(1));
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget object(String path) => SizedBox(
      height: 200,
      child: ContentObjectBuilder(
        sitePath: path,
        whenNear: true,
        placeholder: const SizedBox.expand(),
        builder: (_, _) => Text('drawn $path'),
        unreadable: (_) => const Text('unreadable'),
      ),
    );
    await tester.pumpWidget(
      RepositoryProvider<IContentRepository>.value(
        value: repository,
        child: MaterialApp(
          home: SingleChildScrollView(
            child: Column(children: [object('near'), const SizedBox(height: 3000), object('far')]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => repository.readObject('near')).called(1);
    verifyNever(() => repository.readObject('far'));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2400));
    await tester.pumpAndSettle();
    verify(() => repository.readObject('far')).called(1);
    expect(find.text('drawn far'), findsOneWidget);
  });

  testWidgets('outside a scroll, the object is read at once', (tester) async {
    final repository = MockContentRepository();
    when(() => repository.readObject(any())).thenAnswer((_) async => Uint8List(1));
    await tester.pumpWidget(
      RepositoryProvider<IContentRepository>.value(
        value: repository,
        child: MaterialApp(
          home: ContentObjectBuilder(
            sitePath: 'here',
            whenNear: true,
            builder: (_, _) => const Text('drawn'),
            unreadable: (_) => const Text('unreadable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('drawn'), findsOneWidget);
  });
}
