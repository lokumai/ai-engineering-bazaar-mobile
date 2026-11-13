import 'dart:async';

import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_sting.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/bazaar_app_harness.dart';

/// Draws frames for [duration], as a device does; an animation counts its time from its own first frame.
Future<void> _frames(WidgetTester tester, Duration duration) async {
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

final _scene = find.byKey(WelcomeSting.sceneKey);

Widget _splash({ContentBloc? content, RecordBloc? record, bool reducedMotion = false}) => MultiBlocProvider(
  providers: [
    BlocProvider<ContentBloc>.value(value: content ?? readyContentBloc()),
    BlocProvider<RecordBloc>.value(value: record ?? readyRecordBloc()),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    locale: const Locale('en'),
    builder: (context, child) => reducedMotion
        ? MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!)
        : child!,
    home: const WelcomeSting(child: Text('the app')),
  ),
);

const _ready = RecordReady(
  record: RecordData.empty,
  writeState: WriteSaved(),
  quarantine: null,
  quarantineKept: false,
  launchReadFailed: false,
  undo: null,
);

void main() {
  testWidgets('plays over the app as it opens, then gives way to it with no button (plan 1Y)', (tester) async {
    await tester.pumpWidget(_splash());
    await tester.pump();

    expect(_scene, findsOneWidget);
    expect(find.byType(Text), findsOneWidget, reason: 'no words of its own: only the app below has a text');
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('the app'), findsOneWidget, reason: 'built behind the scene, ready when it fades');

    await _frames(tester, WelcomeSting.entrance + WelcomeSting.exit + const Duration(milliseconds: 100));

    expect(_scene, findsNothing);
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('stays until the record is ready, however long that takes', (tester) async {
    final states = StreamController<RecordState>();
    addTearDown(states.close);
    final record = MockRecordBloc();
    whenListen(record, states.stream, initialState: const RecordLoading());
    await tester.pumpWidget(_splash(record: record));
    await tester.pump();
    await tester.pump(WelcomeSting.entrance * 2);

    expect(_scene, findsOneWidget);

    states.add(_ready);
    await _frames(tester, WelcomeSting.exit + const Duration(milliseconds: 100));
    expect(_scene, findsNothing);
  });

  testWidgets('gives way to the notice when the content cannot be opened', (tester) async {
    final content = MockContentBloc();
    whenListen(
      content,
      const Stream<ContentState>.empty(),
      initialState: const ContentBroken(code: ContentErrorCode.bundledIndexUnreadable),
    );
    await tester.pumpWidget(_splash(content: content, record: loadingRecordBloc()));
    await _frames(tester, WelcomeSting.entrance + WelcomeSting.exit + const Duration(milliseconds: 100));

    expect(_scene, findsNothing);
  });

  testWidgets('a tap during the entrance does not reach the app', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ContentBloc>.value(value: readyContentBloc()),
          BlocProvider<RecordBloc>.value(value: readyRecordBloc()),
        ],
        child: MaterialApp(
          theme: bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: const Locale('en'),
          home: WelcomeSting(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(const Offset(200, 300));
    expect(taps, 0);

    await _frames(tester, WelcomeSting.entrance + WelcomeSting.exit + const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(200, 300));
    expect(taps, 1);
  });

  testWidgets('it says nothing to assistive technology: the app below is read as soon as it is there', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_splash(record: loadingRecordBloc()));
    await tester.pump();
    await tester.pump(WelcomeSting.entrance);

    expect(find.bySemanticsLabel(RegExp('logo|band', caseSensitive: false)), findsNothing);
    expect(
      find.descendant(
        of: _scene,
        matching: find.byWidgetPredicate((widget) => widget is ExcludeSemantics && widget.excluding),
      ),
      findsWidgets,
    );
    expect(tester.semantics.find(find.text('the app')), isNotNull, reason: 'the app below is read');
    handle.dispose();
  });

  testWidgets('under reduced motion it is drawn still and leaves as soon as the app is ready', (tester) async {
    await tester.pumpWidget(_splash(reducedMotion: true));
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump();
    expect(_scene, findsNothing);
  });
}
