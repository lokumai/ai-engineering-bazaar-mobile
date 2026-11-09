import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

class AppDependencies {
  const AppDependencies({this.appConfig = const AppConfig.dev()});

  final AppConfig appConfig;

  /// Crash reporting logs through this on the device; Sentry's own hooks report crashes when a DSN is set.
  IAnalyticsService createAnalyticsService() => LogAnalyticsService();
}
