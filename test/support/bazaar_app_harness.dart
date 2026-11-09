import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'catalog_fixture_index.dart';
import 'content_fixture.dart';

class MockContentBloc extends MockBloc<ContentEvent, ContentState> implements ContentBloc {}

class MockRecordBloc extends MockBloc<RecordEvent, RecordState> implements RecordBloc {}

/// A [ContentBloc] that stays at [ContentReady] over [index], or over [catalogFixtureIndex] when it is null.
ContentBloc readyContentBloc([BundleIndex? index]) {
  final bloc = MockContentBloc();
  whenListen(
    bloc,
    const Stream<ContentState>.empty(),
    initialState: ContentReady(
      index: index ?? catalogFixtureIndex(),
      origin: ContentOrigin.bundled,
      notice: null,
      refresh: const RefreshIdle(),
    ),
  );
  return bloc;
}

/// A [RecordBloc] that stays at [RecordReady] over [record], or over the empty record when it is null.
RecordBloc readyRecordBloc([RecordData? record]) {
  final bloc = MockRecordBloc();
  whenListen(
    bloc,
    const Stream<RecordState>.empty(),
    initialState: RecordReady(
      record: record ?? RecordData.empty,
      writeState: const WriteSaved(),
      quarantine: null,
      quarantineKept: false,
      launchReadFailed: false,
      undo: null,
    ),
  );
  return bloc;
}

/// A [RecordBloc] that stays at [RecordLoading].
RecordBloc loadingRecordBloc() {
  final bloc = MockRecordBloc();
  whenListen(bloc, const Stream<RecordState>.empty(), initialState: const RecordLoading());
  return bloc;
}

/// The app's providers and [MaterialApp.router] over [router], without the app gate: [content] and [record] default to
/// ready blocs, [track] to a new [TrackCubit], and the web links use [testContentBaseUrl].
Widget bazaarTestApp({
  required GoRouter router,
  ContentBloc? content,
  RecordBloc? record,
  TrackCubit? track,
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.android,
}) {
  return RepositoryProvider<WebLinks>.value(
    value: const WebLinks(testContentBaseUrl),
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ContentBloc>.value(value: content ?? readyContentBloc()),
        BlocProvider<RecordBloc>.value(value: record ?? readyRecordBloc()),
        if (track != null) BlocProvider<TrackCubit>.value(value: track) else BlocProvider(create: (_) => TrackCubit()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: bazaarTheme(brightness: brightness, platform: platform),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
}

/// Pumps one frame at a time until [finder] finds a widget, and fails naming [finder] after [maxPumps] frames.
///
/// It never settles, because the app gate's spinner animates until the content and the record are ready.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {int maxPumps = 20}) async {
  for (var pumps = 0; pumps < maxPumps; pumps++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump();
  }
  if (finder.evaluate().isNotEmpty) return;
  throw TestFailure('$finder found nothing after $maxPumps pumps');
}
