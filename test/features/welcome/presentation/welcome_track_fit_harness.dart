import 'dart:io';

import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_track_view.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/catalog_fixture_index.dart';

/// Loads [files] under [family], so text is measured in a real face instead of the test font's squares.
Future<void> loadFace(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(file).readAsBytesSync())));
  }
  await loader.load();
}

/// The Flutter SDK's Roboto, the face Android draws the interface in.
List<String> robotoFiles() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set; flutter test sets it');
  return [
    for (final name in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'])
      '$root/bin/cache/artifacts/material_fonts/$name',
  ];
}

/// Whether Welcome's first step, in [locale], fits a 393 x 852 phone (an iPhone 17, its notch and home bar taken off)
/// with no scrolling: the scroll extent left over.
Future<double> trackStepOverflow(WidgetTester tester, String locale) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
  tester.view.viewPadding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await S.load(Locale(locale));
  final content = MockContentBloc();
  whenListen(
    content,
    const Stream<ContentState>.empty(),
    initialState: ContentReady(
      index: catalogFixtureIndex(),
      origin: ContentOrigin.bundled,
      notice: null,
      refresh: const RefreshUpToDate(),
    ),
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<ContentBloc>.value(value: content),
        BlocProvider<LanguageCubit>(create: (_) => LanguageCubit(initial: locale)),
        BlocProvider<ThemeChoiceCubit>(create: (_) => ThemeChoiceCubit()),
        BlocProvider<AppIconCubit>(create: (_) => AppIconCubit()..load()),
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
        locale: Locale(locale),
        home: WelcomeTrackView(initial: Track.engineers, story: true, onChosen: (_, {required story}) {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final scroll = tester.state<ScrollableState>(
    find.descendant(of: find.byType(WelcomeTrackView), matching: find.byType(Scrollable)),
  );
  return scroll.position.maxScrollExtent;
}
