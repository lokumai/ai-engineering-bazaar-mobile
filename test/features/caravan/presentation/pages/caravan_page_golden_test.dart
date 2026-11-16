import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/features/caravan/application/caravan_cubit.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/pages/caravan_page.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/golden_app.dart';

/// The Caravan at its fifth stop, the caravan in place: reduced motion draws it there at once.
Widget _page(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: goldenScreen(
    MultiBlocProvider(
      providers: [
        BlocProvider<TrackCubit>(create: (_) => TrackCubit()),
        BlocProvider<ContentBloc>.value(value: readyContentBloc()),
        BlocProvider<CaravanCubit>(create: (_) => CaravanCubit()..select(4, count: 22)),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const Scaffold(body: CaravanPage()),
        ),
      ),
    ),
    dark: brightness == Brightness.dark,
  ),
);

void main() {
  goldenTest(
    'CaravanPage light',
    fileName: 'caravan_page_light',
    pumpBeforeTest: (tester) async {
      await tester.pump();
      await tester.pump();
    },
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'the fifth stop', child: _page(Brightness.light))],
    ),
  );

  goldenTest(
    'CaravanPage dark',
    fileName: 'caravan_page_dark',
    pumpBeforeTest: (tester) async {
      await tester.pump();
      await tester.pump();
    },
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'the fifth stop', child: _page(Brightness.dark))],
    ),
  );
}
