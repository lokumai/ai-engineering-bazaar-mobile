@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/progress/presentation/pages/progress_page.dart';
import 'package:ai_engineering_bazaar/features/progress/presentation/widgets/progress_view.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// The record with `alpha/first` completed For Engineers.
RecordData _firstCompleted() => signOff(RecordData.empty, 'alpha/first', null, '2026-03-15T10:00:00.000Z');

/// The progress page alone, with the two module routes a row can open; not `AppRouterFactory`, whose shell bar carries
/// its own `For Engineers` and `For Everyone` segments.
GoRouter _router() {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      // The app's shell gives the page its Scaffold; here the route does.
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: ProgressPage()),
      ),
      GoRoute(path: '/courses/:level/:module', builder: (_, _) => const Placeholder()),
      GoRoute(path: '/everyone/courses/:level/:module', builder: (_, _) => const Placeholder()),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

TrackCubit _trackCubit() {
  final cubit = TrackCubit();
  addTearDown(cubit.close);
  return cubit;
}

Future<void> _pump(
  WidgetTester tester, {
  required GoRouter router,
  required RecordBloc record,
  TrackCubit? track,
}) async {
  await tester.pumpWidget(
    bazaarTestApp(router: router, content: readyContentBloc(), record: record, track: track ?? _trackCubit()),
  );
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Finder _plannedIn(String key) =>
    find.descendant(of: find.byKey(Key('progress_row_$key')), matching: find.bySemanticsLabel('Planned'));

/// A record store in memory: the launch read finds nothing and every write is kept as [lastWritten].
class _MemoryRecordRepository implements IRecordRepository {
  String? lastWritten;

  @override
  Future<RecordLoad> load() async => const RecordLoadEmpty(quarantineKept: false);

  @override
  Future<WriteResult> write(String compactJson) async {
    lastWritten = compactJson;
    return WriteResult.saved;
  }

  @override
  Future<StoredBytes> readStored() => throw UnimplementedError();

  @override
  Future<void> deleteAll() => throw UnimplementedError();

  @override
  Future<void> restore(StoredBytes bytes) => throw UnimplementedError();

  @override
  Future<void> deleteQuarantine() => throw UnimplementedError();
}

void main() {
  testWidgets('shows the title, both tabs with their counts and the legend', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc());

    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('For Engineers'), findsOneWidget);
    expect(find.text('For Everyone'), findsOneWidget);
    expect(find.text('0 of 6'), findsNWidgets(2));
    for (final word in ['Complete', 'Not yet', 'Planned']) {
      expect(find.text(word), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Every module, For Engineers'), findsOneWidget);
    expect(find.bySemanticsLabel('Progress by track'), findsOneWidget);
  });

  testWidgets('the title is a header', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc());

    expect(
      find.ancestor(
        of: find.text('Your progress'),
        matching: find.byWidgetPredicate((widget) => widget is Semantics && (widget.properties.header ?? false)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('prints -- while the record loads', (tester) async {
    await _pump(tester, router: _router(), record: loadingRecordBloc());

    expect(find.text('-- of 6'), findsNWidgets(2));
    for (final dial in ['--/3', '--/2', '--/1']) {
      expect(find.text(dial), findsOneWidget);
    }
  });

  testWidgets('opens on the TrackCubit track and a tab never changes the track', (tester) async {
    final trackCubit = _trackCubit()..select(Track.everyone);
    await _pump(tester, router: _router(), record: readyRecordBloc(), track: trackCubit);

    expect(find.byKey(const Key('progress_panel_everyone')), findsOneWidget);
    expect(find.byKey(const Key('progress_panel_engineers')), findsNothing);
    await _tap(tester, find.text('For Engineers'));

    expect(find.byKey(const Key('progress_panel_engineers')), findsOneWidget);
    expect(find.byKey(const Key('progress_panel_everyone')), findsNothing);
    expect(trackCubit.state, Track.everyone);
  });

  testWidgets('the tab follows the track until a tab is chosen', (tester) async {
    final trackCubit = _trackCubit();
    await _pump(tester, router: _router(), record: readyRecordBloc(), track: trackCubit);
    expect(find.byKey(const Key('progress_panel_engineers')), findsOneWidget);

    trackCubit.select(Track.everyone);
    // The cubit's stream delivers the state in a microtask, so the page rebuilds on the frame after it.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('progress_panel_everyone')), findsOneWidget);

    await _tap(tester, find.text('For Engineers'));
    trackCubit
      ..select(Track.engineers)
      ..select(Track.everyone);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('progress_panel_engineers')), findsOneWidget);
  });

  testWidgets('a level card lists every module in number order with its dial', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc(_firstCompleted()));

    expect(find.text('01'), findsOneWidget);
    expect(find.text('Alpha Level'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('Beta Level'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
    expect(find.text('Gamma Level'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('01 First Module')).dy,
      lessThan(tester.getTopLeft(find.text('02 Second Module')).dy),
    );
    expect(
      tester.getTopLeft(find.text('02 Second Module')).dy,
      lessThan(tester.getTopLeft(find.text('03 Third Module')).dy),
    );
    expect(find.text('06 Sixth Module'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Alpha Level')).dy, lessThan(tester.getTopLeft(find.text('Beta Level')).dy));
  });

  testWidgets('the panel ends with the legend', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc());

    expect(tester.getTopLeft(find.text('06 Sixth Module')).dy, lessThan(tester.getTopLeft(find.text('Complete')).dy));
    expect(tester.getTopLeft(find.text('Complete')).dy, lessThan(tester.getTopLeft(find.text('Not yet')).dy));
    expect(tester.getTopLeft(find.text('Not yet')).dy, lessThan(tester.getTopLeft(find.text('Planned')).dy));
  });

  testWidgets('rows show the For Engineers title and link into the tab track', (tester) async {
    final router = _router();
    await _pump(tester, router: router, record: readyRecordBloc());
    await _tap(tester, find.text('For Everyone'));

    expect(find.text('First Story'), findsNothing);
    expect(find.text('01 First Story'), findsNothing);
    expect(find.text('01 First Module'), findsOneWidget);
    await _tap(tester, find.text('03 Third Module')); // planned rows link as well
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/everyone/courses/alpha/third');
  });

  testWidgets('a row in the For Engineers tab opens the For Engineers module', (tester) async {
    final router = _router();
    await _pump(tester, router: router, record: readyRecordBloc());
    await _tap(tester, find.text('02 Second Module'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/courses/alpha/second');
  });

  testWidgets('a written row toggles the tab track with revision null', (tester) async {
    final recordBloc = readyRecordBloc() as MockRecordBloc;
    await _pump(tester, router: _router(), record: recordBloc);
    await _tap(tester, find.text('For Everyone'));
    await _tap(tester, find.bySemanticsLabel('Complete First Module'));

    final event = verify(() => recordBloc.add(captureAny())).captured.single as CompletionToggled;
    expect((event.key, event.revision, event.track), ('alpha/first', null, Track.everyone));
  });

  testWidgets('a completed row reads as checked', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc(_firstCompleted()));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Complete First Module')),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Complete Second Module')),
      isSemantics(hasCheckedState: true, isChecked: false, hasTapAction: true),
    );
  });

  testWidgets('a completion in one track is not shown in the other tab', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc(_firstCompleted()));
    await _tap(tester, find.text('For Everyone'));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Complete First Module')),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('a planned row has no control and says Planned', (tester) async {
    await _pump(tester, router: _router(), record: readyRecordBloc());

    expect(find.bySemanticsLabel('Complete Third Module'), findsNothing);
    expect(_plannedIn('alpha/third'), findsOneWidget);
    expect(_plannedIn('alpha/second'), findsNothing); // written in For Engineers
    await _tap(tester, find.text('For Everyone'));

    expect(_plannedIn('alpha/second'), findsOneWidget);
    expect(find.bySemanticsLabel('Complete Second Module'), findsNothing);
  });

  testWidgets('a toggle in one tab leaves the other tab counts unchanged', (tester) async {
    final repository = _MemoryRecordRepository();
    final record = RecordBloc(repository: repository)..add(const RecordStarted());
    addTearDown(record.close);
    await _pump(tester, router: _router(), record: record);
    await tester.pumpAndSettle();
    expect(find.text('0 of 6'), findsNWidgets(2));

    await _tap(tester, find.bySemanticsLabel('Complete First Module'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 6'), findsOneWidget); // For Engineers
    expect(find.text('0 of 6'), findsOneWidget); // For Everyone
    expect(find.text('1/3'), findsOneWidget);
    expect(repository.lastWritten, contains('"sheets":{"alpha/first":{"signedOff":"'));
    expect(repository.lastWritten, contains('"everyoneSheets":{}'));

    await _tap(tester, find.text('For Everyone'));
    expect(find.text('0/3'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Complete First Module'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 6'), findsNWidgets(2));
    expect(repository.lastWritten, contains('"everyoneSheets":{"alpha/first":{"signedOff":"'));

    await _tap(tester, find.text('For Engineers'));
    expect(find.text('1/3'), findsOneWidget); // the For Engineers dial is unchanged by the For Everyone toggle
  });

  testWidgets('ProgressView shows its slots above the tabs and below the panel', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => switch (context.read<ContentBloc>().state) {
            ContentReady(:final index) => ProgressView(
              index: index,
              aboveTabs: const SizedBox(key: Key('above'), height: 10),
              belowCards: const SizedBox(key: Key('below'), height: 10),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(bazaarTestApp(router: router));
    await tester.pump();

    final above = tester.getTopLeft(find.byKey(const Key('above'))).dy;
    expect(tester.getTopLeft(find.text('Your progress')).dy, lessThan(above));
    expect(above, lessThan(tester.getTopLeft(find.text('For Engineers')).dy));
    expect(tester.getTopLeft(find.text('Planned')).dy, lessThan(tester.getTopLeft(find.byKey(const Key('below'))).dy));
  });

  testWidgets('ProgressPage shows nothing while the content loads', (tester) async {
    final content = MockContentBloc();
    whenListen(content, const Stream<ContentState>.empty(), initialState: const ContentLoading());
    await tester.pumpWidget(bazaarTestApp(router: _router(), content: content, record: readyRecordBloc()));
    await tester.pump();

    expect(find.byType(ProgressView), findsNothing);
    expect(find.text('Your progress'), findsNothing);
  });

  testWidgets('text scale 2.0', (tester) async {
    await pumpAtTextScale(
      tester,
      bazaarTestApp(
        router: _router(),
        content: readyContentBloc(),
        record: readyRecordBloc(_firstCompleted()),
        track: _trackCubit(),
      ),
      scale: 2.0,
    );

    expect(tester.takeException(), isNull);
    for (final target in [
      find.text('For Everyone'),
      find.bySemanticsLabel('Complete First Module'),
      find.text('01 First Module'),
    ]) {
      await tester.ensureVisible(target);
      await tester.pump();
      expectHittable(tester, target);
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    await tester.pumpWidget(
      bazaarTestApp(
        platform: defaultTargetPlatform,
        router: _router(),
        content: readyContentBloc(),
        record: readyRecordBloc(_firstCompleted()),
        track: _trackCubit(),
      ),
    );
    await tester.pump();

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
