import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';

/// Provides what [dependencies] holds to the widget tree below it, and starts [ContentBloc] at once (spec 3.7).
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
      ],
      child: BlocProvider<ContentBloc>(
        lazy: false,
        create: (context) => ContentBloc(repository: context.read<IContentRepository>())..add(const ContentStarted()),
        child: child,
      ),
    );
  }
}
