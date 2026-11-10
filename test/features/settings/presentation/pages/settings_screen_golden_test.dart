import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_screen.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/bazaar_app_harness.dart';
import '../../../../support/catalog_fixture_index.dart';
import '../../../../support/test_env.dart';
import '../../../../support/golden_app.dart';

/// The release page (no developer console) over the fixture index, bundled and up to date.
Widget _screen({required bool dark}) {
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
  // The data section's flows read the record and the two ports (plan 1AB).
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<IBackupGateway>.value(value: MockBackupGateway()),
      RepositoryProvider<IRecordRepository>.value(value: MockRecordRepository()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ContentBloc>.value(value: content),
        BlocProvider<RecordBloc>.value(value: readyRecordBloc()),
        BlocProvider<TrackCubit>(create: (_) => TrackCubit()),
        BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
        BlocProvider<QuizScoresBloc>(create: (_) => QuizScoresBloc(store: MemoryQuizScoreStore())),
      ],
      child: goldenScreen(const SettingsScreen(openDevConsole: null), dark: dark),
    ),
  );
}

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest(
    'SettingsScreen light',
    fileName: 'settings_screen_light',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: _screen(dark: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'SettingsScreen dark',
    fileName: 'settings_screen_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: _screen(dark: true)),
        ),
      ],
    ),
  );
}
