import 'package:ai_engineering_bazaar/core/analytics/analytics_service.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// The default [IAnalyticsService]: writes each error to [AppLogger], with no SDK.
class LogAnalyticsService implements IAnalyticsService {
  static final _log = AppLogger.getLogger('Analytics');

  @override
  void logError({required Object error, StackTrace? stackTrace, String? reason}) {
    _log.error('non_fatal_error: {} reason: {}', [error, reason ?? '-']);
    if (stackTrace != null) {
      _log.error('stack_trace: {}', [() => stackTrace.toString().split('\n').take(5).join('\n')]);
    }
  }
}
