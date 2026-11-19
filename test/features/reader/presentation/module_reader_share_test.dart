@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';
import '../../../support/content_fixture.dart';

final class _Sheet implements IShareSheet {
  final shared = <String>[];

  @override
  Future<bool> share(String text) async {
    shared.add(text);
    return true;
  }
}

final _doc = testDoc(
  body: [
    ParagraphBlock(inlines: [TextInline(text: 'The lamp is lit.')], lead: false),
  ],
);

void main() {
  testWidgets("Share sends the module's title and its page on the site, at the address the bundle gives (plan 17.3)", (
    tester,
  ) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer((_) async => _doc);
    final sheet = _Sheet();
    final router = AppRouterFactory(initialLocation: '/courses/alpha/first').create();
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router, repository: repository, shareSheet: sheet));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-share')));
    await tester.pump();

    final [title, link] = sheet.shared.single.split('\n');
    expect(title, _doc.title);
    expect(link, startsWith(testContentBaseUrl));
    expect(link, endsWith('courses/alpha/first/'));
  });
}
