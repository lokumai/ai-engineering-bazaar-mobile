import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// Provides what [dependencies] holds to the widget tree below it, and starts [ContentBloc] and [RecordBloc] at once
/// (spec 3.7). It also provides the current track ([TrackCubit], in memory) and the site's address ([WebLinks]).
class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.dependencies, required this.child});

  final AppDependencies dependencies;
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
          BlocProvider<TrackCubit>(create: (_) => TrackCubit()),
        ],
        child: child,
      ),
    );
  }
}
