import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:ai_engineering_bazaar/core/analytics/analytics_service.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';

/// Builds the infrastructure the app runs on; a test subclass overrides the factories with doubles.
class AppDependencies {
  const AppDependencies({
    this.appConfig = const AppConfig.dev(),
    @visibleForTesting this.cacheDirectory = getApplicationCacheDirectory,
  });

  final AppConfig appConfig;

  /// Where the downloaded content is stored; resolved by the repository's `open()`, not here.
  final Future<Directory> Function() cacheDirectory;

  /// Crash reporting logs through this on the device; Sentry's own hooks report crashes when a DSN is set.
  IAnalyticsService createAnalyticsService() => LogAnalyticsService();

  /// The content repository over the bundled snapshot, the cache directory and the site at
  /// [AppConfig.contentBaseUrl]; built synchronously, it touches no file until `open()`.
  IContentRepository createContentRepository() => FileContentRepository(
    bundled: BundledContent(bundle: rootBundle),
    cacheDirectory: cacheDirectory,
    http: ContentHttp(client: http.Client(), contentBaseUrl: appConfig.contentBaseUrl),
  );
}
