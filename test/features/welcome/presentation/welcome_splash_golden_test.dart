import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_splash.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../support/bazaar_app_harness.dart';
import '../../../support/golden_app.dart';

/// The gate as its entrance ends, while the record still loads: reduced motion draws it in place at once.
Widget _splash(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: goldenScreen(
    MultiBlocProvider(
      providers: [
        BlocProvider<ContentBloc>.value(value: readyContentBloc()),
        BlocProvider<RecordBloc>.value(value: loadingRecordBloc()),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const WelcomeSplash(child: SizedBox.expand()),
        ),
      ),
    ),
    dark: brightness == Brightness.dark,
  ),
);

void main() {
  goldenTest(
    'WelcomeSplash light',
    fileName: 'welcome_splash_light',
    // The pictures decode off the frame, so they are loaded before the capture.
    pumpBeforeTest: precacheImages,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'opening', child: _splash(Brightness.light))],
    ),
  );

  goldenTest(
    'WelcomeSplash dark',
    fileName: 'welcome_splash_dark',
    pumpBeforeTest: precacheImages,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'opening', child: _splash(Brightness.dark))],
    ),
  );
}
