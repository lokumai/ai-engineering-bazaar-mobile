import 'dart:async';

import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_sting.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
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

/// A store whose choice is read only when [read] completes.
final class _SlowStore implements IAppIconStore {
  final read = Completer<BazaarIcon?>();

  @override
  Future<BazaarIcon?> chosen() => read.future;

  @override
  Future<void> choose(BazaarIcon icon) async {}
}

/// A store that holds [icon] as chosen.
final class _ChosenStore implements IAppIconStore {
  const _ChosenStore(this.icon);

  final BazaarIcon icon;

  @override
  Future<BazaarIcon?> chosen() async => icon;

  @override
  Future<void> choose(BazaarIcon icon) async {}
}

/// Draws frames for [duration], as a device does; an animation counts its time from its own first frame.
Future<void> _frames(WidgetTester tester, Duration duration) async {
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

final _scene = find.byKey(WelcomeSting.sceneKey);

/// A robot that greets for [greeting], then says it is done; never, with null.
class _Robot extends StatefulWidget {
  const _Robot({required this.onDone, this.greeting = _greeting});

  final VoidCallback onDone;
  final Duration? greeting;

  @override
  State<_Robot> createState() => _RobotState();
}

class _RobotState extends State<_Robot> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.greeting case final greeting?) _timer = Timer(greeting, widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand(key: _robotKey);
}

const _greeting = Duration(milliseconds: 850);
const _robotKey = Key('the robot');
final _robot = find.byKey(_robotKey);

Widget _splash({
  ContentBloc? content,
  RecordBloc? record,
  AppIconCubit? appIcon,
  bool reducedMotion = false,
  Duration? greeting = _greeting,
  ThemeMode themeMode = ThemeMode.light,
}) => MultiBlocProvider(
  providers: [
    if (appIcon != null)
      BlocProvider<AppIconCubit>.value(value: appIcon)
    else
      BlocProvider<AppIconCubit>(create: (_) => AppIconCubit()..load()),
    BlocProvider<ContentBloc>.value(value: content ?? readyContentBloc()),
    BlocProvider<RecordBloc>.value(value: record ?? readyRecordBloc()),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android),
    darkTheme: bazaarTheme(brightness: Brightness.dark, platform: TargetPlatform.android),
    themeMode: themeMode,
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
    home: WelcomeSting(
      robot: (onDone) => _Robot(onDone: onDone, greeting: greeting),
      child: const Text('the app'),
    ),
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
  testWidgets('the robot greets over the app as it opens, then fades into it with no button (plan 1Y, 9.10)', (
    tester,
  ) async {
    await tester.pumpWidget(_splash());
    await tester.pump();

    expect(_scene, findsOneWidget);
    expect(find.descendant(of: _scene, matching: _robot), findsOneWidget);
    expect(find.byType(Text), findsOneWidget, reason: 'no words of its own: only the app below has a text');
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('the app'), findsOneWidget, reason: 'built behind the scene, ready when it fades');

    await _frames(tester, _greeting - const Duration(milliseconds: 100));
    expect(_scene, findsOneWidget, reason: 'the app is ready, but the robot is still greeting');

    await _frames(tester, const Duration(milliseconds: 100) + WelcomeSting.leave + const Duration(milliseconds: 100));
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
    await _frames(tester, _greeting * 2);

    expect(_scene, findsOneWidget);

    states.add(_ready);
    await _frames(tester, WelcomeSting.leave + const Duration(milliseconds: 100));
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
    await _frames(tester, _greeting + WelcomeSting.leave + const Duration(milliseconds: 100));

    expect(_scene, findsNothing);
  });

  testWidgets('a robot that never says it is done is left after a while', (tester) async {
    await tester.pumpWidget(_splash(greeting: null));
    await tester.pump();
    await _frames(tester, WelcomeSting.longest - const Duration(milliseconds: 100));
    expect(_scene, findsOneWidget);

    await _frames(tester, const Duration(milliseconds: 100) + WelcomeSting.leave + const Duration(milliseconds: 100));
    expect(_scene, findsNothing);
  });

  testWidgets('a tap during the greeting does not reach the app', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ContentBloc>.value(value: readyContentBloc()),
          BlocProvider<RecordBloc>.value(value: readyRecordBloc()),
          BlocProvider<AppIconCubit>(create: (_) => AppIconCubit()..load()),
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
            robot: (onDone) => _Robot(onDone: onDone),
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

    await _frames(tester, _greeting + WelcomeSting.leave + const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(200, 300));
    expect(taps, 1);
  });

  testWidgets('it says nothing to assistive technology: the app below is read as soon as it is there', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_splash(record: loadingRecordBloc()));
    await tester.pump();

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

  testWidgets('under reduced motion it leaves as soon as the app is ready, the robot standing still', (tester) async {
    await tester.pumpWidget(_splash(reducedMotion: true, greeting: null));
    await tester.pump();
    await tester.pump();
    expect(_scene, findsNothing);
  });

  testWidgets('waits for the chosen icon: until it is read, only the default ground shows, and no robot', (
    tester,
  ) async {
    final store = _SlowStore();
    final appIcon = AppIconCubit(store: store)..load();
    addTearDown(appIcon.close);
    await tester.pumpWidget(_splash(appIcon: appIcon));
    await _frames(tester, _greeting + WelcomeSting.leave + const Duration(milliseconds: 100));

    expect(_scene, findsOneWidget);
    expect(_robot, findsNothing);
    expect(tester.widget<ColoredBox>(find.byKey(WelcomeSting.groundKey)).color, BazaarIcon.fezCream.ground);

    store.read.complete(null);
    await tester.pump();
    await tester.pump();
    expect(_robot, findsOneWidget);
    await _frames(tester, _greeting + WelcomeSting.leave + const Duration(milliseconds: 100));

    expect(_scene, findsNothing);
  });

  for (final (mode, brightness) in [(ThemeMode.light, Brightness.light), (ThemeMode.dark, Brightness.dark)]) {
    testWidgets(
      'stands on the ground the reader reads on, ${brightness.name}, whatever the icon (the owner, 2026-11-14)',
      (tester) async {
        final appIcon = AppIconCubit(store: const _ChosenStore(BazaarIcon.tvDark))..load();
        addTearDown(appIcon.close);
        await tester.pumpWidget(_splash(appIcon: appIcon, themeMode: mode));
        await tester.pump();
        expect(
          tester.widget<ColoredBox>(find.byKey(WelcomeSting.groundKey)).color,
          BazaarIcon.tvDark.ground,
          reason: 'it starts in the launch screen colour',
        );
        await _frames(tester, WelcomeSting.tint + const Duration(milliseconds: 32));

        final ground = bazaarTheme(brightness: brightness, platform: TargetPlatform.android).scaffoldBackgroundColor;
        expect(tester.widget<ColoredBox>(find.byKey(WelcomeSting.groundKey)).color, ground);
        await _frames(tester, _greeting + WelcomeSting.leave + const Duration(milliseconds: 100));
      },
    );
  }

  testWidgets('the app opens out of a circle where the robot stood, as the robot shrinks away, in about a second', (
    tester,
  ) async {
    await tester.pumpWidget(_splash());
    await tester.pump();
    await _frames(tester, _greeting + const Duration(milliseconds: 32));
    await _frames(tester, WelcomeSting.leave * 0.6);

    expect(_scene, findsOneWidget, reason: 'still leaving');
    final clip = tester.widget<ClipPath>(find.descendant(of: _scene, matching: find.byType(ClipPath)).first);
    final size = tester.getSize(_scene);
    final path = clip.clipper!.getClip(size);
    expect(path.contains(size.center(Offset.zero)), isFalse, reason: 'the middle is open onto the app');
    expect(path.contains(const Offset(2, 2)), isTrue, reason: 'the corners still covered');
    final scales = tester
        .widgetList<Transform>(find.ancestor(of: _robot, matching: find.byType(Transform)))
        .map((transform) => transform.transform.storage[0]);
    expect(scales.any((scale) => scale < 0.5), isTrue, reason: 'the robot is shrinking away');

    await _frames(tester, WelcomeSting.leave * 0.5);
    expect(_scene, findsNothing);
    expect(_greeting + WelcomeSting.leave, lessThan(const Duration(milliseconds: 1400)));
  });
}
