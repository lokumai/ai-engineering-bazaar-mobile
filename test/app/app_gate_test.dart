@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/app_gate.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/accessibility.dart';
import '../support/bazaar_app_harness.dart';
import '../support/catalog_fixture_index.dart';

const _brokenTitle = 'The course cannot be opened';
const _brokenMessage =
    'The course content in this app could not be opened. An update of the app restores it. '
    'Your progress on this device is kept.';
const _storageMessage =
    'The app could not use its storage for the course content. Your progress on this device is kept.';

final _router = find.text('router');
final _spinner = find.byType(CircularProgressIndicator);

const _recordReady = RecordReady(
  record: RecordData.empty,
  writeState: WriteSaved(),
  quarantine: null,
  quarantineKept: false,
  launchReadFailed: false,
  undo: null,
);

ContentReady _contentReady() => ContentReady(
  index: catalogFixtureIndex(),
  origin: ContentOrigin.bundled,
  notice: null,
  refresh: const RefreshIdle(),
);

/// The gate over a stand-in router, with the two blocs held at [content] and [record].
Widget _gate(ContentState content, RecordState record, {TargetPlatform? platform}) {
  final contentBloc = MockContentBloc();
  whenListen(contentBloc, const Stream<ContentState>.empty(), initialState: content);
  final recordBloc = MockRecordBloc();
  whenListen(recordBloc, const Stream<RecordState>.empty(), initialState: record);
  return MultiBlocProvider(
    providers: [
      BlocProvider<ContentBloc>.value(value: contentBloc),
      BlocProvider<RecordBloc>.value(value: recordBloc),
    ],
    child: MaterialApp(
      theme: bazaarTheme(brightness: Brightness.light, platform: platform ?? defaultTargetPlatform),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => AppGate(child: child!),
      home: const Text('router'),
    ),
  );
}

void main() {
  // (content, record, router shown, spinner shown)
  final pairs = <(String, ContentState Function(), RecordState, bool, bool)>[
    ('content loading, record loading', () => const ContentLoading(), const RecordLoading(), false, true),
    ('content ready, record loading', _contentReady, const RecordLoading(), false, true),
    ('content loading, record ready', () => const ContentLoading(), _recordReady, false, true),
    ('content ready, record ready', _contentReady, _recordReady, true, false),
  ];
  for (final (name, content, record, routerShown, spinnerShown) in pairs) {
    testWidgets('$name: router ${routerShown ? 'shown' : 'hidden'}', (tester) async {
      await tester.pumpWidget(_gate(content(), record));
      await tester.pump();

      expect(_router, routerShown ? findsOneWidget : findsNothing);
      expect(_spinner, spinnerShown ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('broken content shows the broken view instead of the router', (tester) async {
    await tester.pumpWidget(_gate(const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable), _recordReady));
    await tester.pump();

    expect(_router, findsNothing);
    expect(_spinner, findsNothing);
    expect(find.text(_brokenTitle), findsOneWidget);
    expect(find.text(_brokenMessage), findsOneWidget);
  });

  // A reinstall deletes the progress on iOS, and on Android unless a backup has run; the broken view never advises it.
  for (final code in ContentErrorCode.values) {
    final message = code == ContentErrorCode.storage ? _storageMessage : _brokenMessage;
    testWidgets('broken content ($code) says its own line and keeps the progress', (tester) async {
      await tester.pumpWidget(_gate(ContentBroken(code: code), _recordReady));
      await tester.pump();

      expect(find.text(message), findsOneWidget);
      expect(find.textContaining('Your progress on this device is kept.'), findsOneWidget);
      expect(find.textContaining(RegExp('reinstall', caseSensitive: false)), findsNothing);
    });
  }

  testWidgets('the broken view at text scale 2.0', (tester) async {
    await pumpAtTextScale(
      tester,
      _gate(const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable), _recordReady),
      scale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.text(_brokenTitle), findsOneWidget);
  });

  testWidgets('the loading view at text scale 2.0', (tester) async {
    await pumpAtTextScale(tester, _gate(const ContentLoading(), const RecordLoading()), scale: 2.0);

    expect(tester.takeException(), isNull);
    expect(_spinner, findsOneWidget);
  });

  testWidgets('the broken view meets the accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(
      _gate(
        const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable),
        _recordReady,
        platform: defaultTargetPlatform,
      ),
    );
    await tester.pump();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });

  testWidgets('the loading view meets the accessibility guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(_gate(const ContentLoading(), const RecordLoading(), platform: defaultTargetPlatform));
    await tester.pump();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
