import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/pages/caravan_page.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../support/golden_app.dart';

/// The Caravan's coming soon page with the caravan in place: reduced motion draws it there at once.
Widget _page(Brightness brightness) => SizedBox.fromSize(
  size: kGoldenScreenSize,
  child: goldenScreen(
    BlocProvider<TrackCubit>(
      create: (_) => TrackCubit(),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: Scaffold(body: const CaravanPage()),
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
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'coming soon', child: _page(Brightness.light))],
    ),
  );

  goldenTest(
    'CaravanPage dark',
    fileName: 'caravan_page_dark',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [GoldenTestScenario(name: 'coming soon', child: _page(Brightness.dark))],
    ),
  );
}
