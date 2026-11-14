import 'dart:ui' show PlatformDispatcher;

import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/features/caravan/application/caravan_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_query_cubit.dart';
import 'package:ai_engineering_bazaar/features/quiz/application/quiz_fold_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_cubit.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_texts.dart';
import 'package:ai_engineering_bazaar/features/settings/application/feedback_sender.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/application/quiz_scores_bloc.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';

/// Provides what [dependencies] holds to the widget tree below it, and starts [ContentBloc] and [RecordBloc] at once
/// (spec 3.7). It also provides the current track ([TrackCubit], which reads the chosen one at once) and the site's address ([WebLinks]).
class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.dependencies, required this.child, this.appIcon});

  final AppDependencies dependencies;

  /// The app icon the boot read before the first frame; null when it was not read, and the cubit reads it.
  final BazaarIcon? appIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: dependencies.appConfig),
        RepositoryProvider<IContentRepository>(create: (_) => dependencies.createContentRepository()),
        RepositoryProvider<IRecordRepository>(create: (_) => dependencies.createRecordRepository()),
        RepositoryProvider<IBackupGateway>(create: (_) => dependencies.createBackupGateway()),
        RepositoryProvider<WebLinks>(create: (_) => WebLinks(dependencies.appConfig.contentBaseUrl)),
        RepositoryProvider<IWelcomeStore>(create: (_) => dependencies.createWelcomeStore()),
        RepositoryProvider<ITrackStore>(create: (_) => dependencies.createTrackStore()),
        RepositoryProvider<ILanguageStore>(create: (_) => dependencies.createLanguageStore()),
        RepositoryProvider<IThemeStore>(create: (_) => dependencies.createThemeStore()),
        RepositoryProvider<IAppIconStore>(create: (_) => dependencies.createAppIconStore()),
        RepositoryProvider<IAppIconSwitch>(create: (_) => dependencies.createAppIconSwitch()),
        RepositoryProvider<IQuizScoreStore>(create: (_) => dependencies.createQuizScoreStore()),
        RepositoryProvider<IReadingPlaceStore>(create: (_) => dependencies.createReadingPlaceStore()),
        RepositoryProvider<IFeedbackSender>(create: (_) => dependencies.createFeedbackSender()),
        RepositoryProvider<IPocketModelStore>(create: (_) => dependencies.createPocketModelStore()),
        RepositoryProvider<IRobotOutfitStore>(create: (_) => dependencies.createRobotOutfitStore()),
        RepositoryProvider<IPocketButtonStore>(create: (_) => dependencies.createPocketButtonStore()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ContentBloc>(
            lazy: false,
            create: (context) =>
                ContentBloc(repository: context.read<IContentRepository>())..add(const ContentStarted()),
          ),
          BlocProvider<RecordBloc>(
            lazy: false,
            create: (context) => RecordBloc(repository: context.read<IRecordRepository>())..add(const RecordStarted()),
          ),
          BlocProvider<TrackCubit>(
            lazy: false,
            create: (context) => TrackCubit(store: context.read<ITrackStore>())..load(),
          ),
          BlocProvider<QuizScoresBloc>(
            lazy: false,
            create: (context) => QuizScoresBloc(store: context.read<IQuizScoreStore>())..add(const QuizScoresStarted()),
          ),
          BlocProvider<ReadingPlacesBloc>(
            lazy: false,
            create: (context) =>
                ReadingPlacesBloc(store: context.read<IReadingPlaceStore>())..add(const ReadingPlacesStarted()),
          ),
          // Which levels the catalog and the Quiz tab show open: in memory, so a new launch starts afresh.
          BlocProvider<CatalogFoldCubit>(create: (_) => CatalogFoldCubit()),
          // The words in the catalog's search, kept the same way.
          BlocProvider<CatalogQueryCubit>(create: (_) => CatalogQueryCubit()),
          BlocProvider<QuizFoldCubit>(create: (_) => QuizFoldCubit()),
          // The Caravan's chosen stop, kept the same way, so the tab opens where the caravan was left.
          BlocProvider<CaravanCubit>(create: (_) => CaravanCubit()),
          // The pocket model, shared by its button in the shell's corner and the sheet it opens (plan 9.4).
          BlocProvider<PocketModelBloc>(
            create: (context) => PocketModelBloc(
              store: context.read<IPocketModelStore>(),
              // It reads the modules the reader finished from the course on this device (plan 9.6).
              texts: ContentPocketTexts(
                repository: context.read<IContentRepository>(),
                content: context.read<ContentBloc>(),
              ),
            )..add(const PocketModelStarted()),
          ),
          // The robot's outfit, which its button, its sheet and its wardrobe wear (plan 9.9).
          BlocProvider<RobotOutfitCubit>(
            create: (context) => RobotOutfitCubit(store: context.read<IRobotOutfitStore>())..load(),
          ),
          // Whether its button shows, which Settings changes and the shell reads (plan 9.9).
          BlocProvider<PocketButtonCubit>(
            lazy: false,
            create: (context) => PocketButtonCubit(store: context.read<IPocketButtonStore>())..load(),
          ),
          BlocProvider<LanguageCubit>(
            lazy: false,
            create: (context) => LanguageCubit(
              store: context.read<ILanguageStore>(),
              initial: PlatformDispatcher.instance.locale.languageCode,
            )..load(),
          ),
          BlocProvider<ThemeChoiceCubit>(
            lazy: false,
            create: (context) => ThemeChoiceCubit(store: context.read<IThemeStore>())..load(),
          ),
          // The opening waits for it, to play in the chosen icon's colours.
          BlocProvider<AppIconCubit>(
            lazy: false,
            create: (context) => AppIconCubit(
              store: context.read<IAppIconStore>(),
              iconSwitch: context.read<IAppIconSwitch>(),
              initial: appIcon,
            )..load(),
          ),
        ],
        child: child,
      ),
    );
  }
}
