import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/tour/application/tour_cubit.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:ai_engineering_bazaar/features/settings/application/feedback_sender.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/features/caravan/application/caravan_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_query_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search_indexes.dart';
import 'package:ai_engineering_bazaar/features/quiz/application/quiz_fold_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ai_engineering_bazaar/shared/robot_level/robot_level_cubit.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_engineering_bazaar/infrastructure/transfer/deflate_transfer_packer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_classes.dart';
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

/// A content repository on which every object and document read throws [ContentMissingException] naming its path, so
/// a page that reads content settles on its unreadable state instead of waiting.
MockContentRepository missingContentRepository() {
  final repository = MockContentRepository();
  Future<Never> missing(Invocation invocation) async =>
      throw ContentMissingException(invocation.positionalArguments.first as String);
  when(() => repository.readObject(any())).thenAnswer(missing);
  when(() => repository.readModuleDoc(any())).thenAnswer(missing);
  when(() => repository.readLevelDoc(any())).thenAnswer(missing);
  when(() => repository.readStoryDoc(any())).thenAnswer(missing);
  return repository;
}

/// The app's providers and [MaterialApp.router] over [router], without the app gate: [content] and [record] default to
/// ready blocs, [track] to a new [TrackCubit], [repository] to [missingContentRepository], [backupGateway] and
/// [recordRepository] (which the Settings page's data line reads) to fresh mocks, [speech] to no voice, [shareSheet] to
/// none, and the web
/// links use [testContentBaseUrl]. The interface is in [locale], English by default.
Widget bazaarTestApp({
  required GoRouter router,
  ContentBloc? content,
  RecordBloc? record,
  TrackCubit? track,
  LanguageCubit? language,
  ThemeChoiceCubit? themeChoice,
  AppIconCubit? appIcon,
  QuizScoresBloc? scores,
  ReviewBloc? review,
  ReadingPlacesBloc? places,
  CaravanCubit? caravan,
  IContentRepository? repository,
  IBackupGateway? backupGateway,
  IRecordRepository? recordRepository,
  IFeedbackSender? feedbackSender,
  IPocketModelStore? pocketStore,
  IPocketTexts? pocketTexts,
  RobotOutfitCubit? robotOutfit,
  PocketButtonCubit? pocketButton,
  TourCubit? tour,
  RobotLevelCubit? robotLevel,
  ReadingStyleCubit? readingStyle,
  ISpeech? speech,
  IShareSheet? shareSheet,
  ICodeScanner? codeScanner,
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<WebLinks>.value(value: const WebLinks(testContentBaseUrl)),
      RepositoryProvider<IContentRepository>.value(value: repository ?? missingContentRepository()),
      RepositoryProvider<IBackupGateway>.value(value: backupGateway ?? MockBackupGateway()),
      RepositoryProvider<IRecordRepository>.value(value: recordRepository ?? MockRecordRepository()),
      RepositoryProvider<IFeedbackSender>.value(value: feedbackSender ?? MockFeedbackSender()),
      RepositoryProvider<IPocketModelStore>.value(value: pocketStore ?? MemoryPocketModelStore()),
      RepositoryProvider<ISpeech>.value(value: speech ?? const NoSpeech()),
      RepositoryProvider<IShareSheet>.value(value: shareSheet ?? const NoShareSheet()),
      RepositoryProvider<ICodeScanner>.value(value: codeScanner ?? const NoCodeScanner()),
      RepositoryProvider<ILinkSource>.value(value: const NoLinkSource()),
      RepositoryProvider<ITransferPacker>.value(value: const DeflateTransferPacker()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ContentBloc>.value(value: content ?? readyContentBloc()),
        BlocProvider<RecordBloc>.value(value: record ?? readyRecordBloc()),
        if (track != null) BlocProvider<TrackCubit>.value(value: track) else BlocProvider(create: (_) => TrackCubit()),
        if (scores != null)
          BlocProvider<QuizScoresBloc>.value(value: scores)
        else
          BlocProvider<QuizScoresBloc>(
            create: (_) => QuizScoresBloc(store: MemoryQuizScoreStore())..add(const QuizScoresStarted()),
          ),
        if (review != null)
          BlocProvider<ReviewBloc>.value(value: review)
        else
          BlocProvider<ReviewBloc>(create: (_) => ReviewBloc(store: MemoryReviewStore())..add(const ReviewStarted())),
        BlocProvider<StudyNotesCubit>(
          create: (context) => StudyNotesCubit(repository: context.read<IContentRepository>()),
        ),
        if (places != null)
          BlocProvider<ReadingPlacesBloc>.value(value: places)
        else
          BlocProvider<ReadingPlacesBloc>(
            create: (_) => ReadingPlacesBloc(store: MemoryReadingPlaceStore())..add(const ReadingPlacesStarted()),
          ),
        BlocProvider<CatalogFoldCubit>(create: (_) => CatalogFoldCubit()),
        BlocProvider<CatalogQueryCubit>(create: (_) => CatalogQueryCubit()),
        RepositoryProvider<CatalogSearchIndexes>(create: (_) => CatalogSearchIndexes()),
        BlocProvider<QuizFoldCubit>(create: (_) => QuizFoldCubit()),
        BlocProvider<ListenCubit>(create: (context) => ListenCubit(speech: context.read<ISpeech>())),
        // Above the pages, as app_scope.dart provides it (opus review 11, record finding 2).
        BlocProvider<DataBloc>(
          create: (context) => DataBloc(
            recordBloc: context.read<RecordBloc>(),
            gateway: context.read<IBackupGateway>(),
            repository: context.read<IRecordRepository>(),
            scores: context.read<QuizScoresBloc>(),
            review: context.read<ReviewBloc>(),
            places: context.read<ReadingPlacesBloc>(),
            listen: context.read<ListenCubit>(),
          ),
        ),
        if (caravan != null)
          BlocProvider<CaravanCubit>.value(value: caravan)
        else
          BlocProvider<CaravanCubit>(create: (_) => CaravanCubit()),
        BlocProvider<RobotOutfitCubit>(create: (_) => robotOutfit ?? RobotOutfitCubit(store: MemoryRobotOutfitStore())),
        BlocProvider<PocketButtonCubit>(create: (_) => pocketButton ?? PocketButtonCubit()),
        // Not loaded unless a test passes one: no tour shows over the pages.
        BlocProvider<TourCubit>(create: (_) => tour ?? TourCubit(store: MemoryTourStore())),
        BlocProvider<RobotLevelCubit>(create: (_) => robotLevel ?? RobotLevelCubit()),
        BlocProvider<ReadingStyleCubit>(create: (_) => readingStyle ?? ReadingStyleCubit()),
        BlocProvider<PocketModelBloc>(
          create: (context) =>
              PocketModelBloc(store: context.read<IPocketModelStore>(), texts: pocketTexts)
                ..add(const PocketModelStarted()),
        ),
        if (language != null)
          BlocProvider<LanguageCubit>.value(value: language)
        else
          BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
        if (themeChoice != null)
          BlocProvider<ThemeChoiceCubit>.value(value: themeChoice)
        else
          BlocProvider<ThemeChoiceCubit>(create: (_) => ThemeChoiceCubit()),
        if (appIcon != null)
          BlocProvider<AppIconCubit>.value(value: appIcon)
        else
          BlocProvider<AppIconCubit>(create: (_) => AppIconCubit()..load()),
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
        locale: locale,
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
