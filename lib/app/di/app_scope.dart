import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';

/// Provides what [dependencies] holds to the widget tree below it.
class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.dependencies, required this.child});

  final AppDependencies dependencies;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppConfig>.value(value: dependencies.appConfig, child: child);
  }
}
