import 'package:ai_engineering_bazaar/app/router/app_root_page.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/app/router/home_placeholder_page.dart';
import 'package:ai_engineering_bazaar/app/router/not_found_page.dart';
import 'package:ai_engineering_bazaar/app/shell/app_shell.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/settings/navigation/settings_routes.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

class AppRouterFactory {
  const AppRouterFactory();

  static final _log = AppLogger.getLogger('AppRouterFactory');

  GoRouter create() {
    return GoRouter(
      initialLocation: ApplicationRoutesConstants.home,
      debugLogDiagnostics: true,
      errorPageBuilder: (context, state) {
        // The page tells the user in the app language; the router's own error, in English, goes to the log.
        _log.warn('No page for location {}: {}', [state.uri, state.error]);
        return appRootPage(
          state: state,
          // An error state has no route name or path, and an unnamed page is invisible to analytics.
          name: ApplicationRoutesConstants.notFound,
          child: const NotFoundPage(),
        );
      },
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => appPlatformPage(
            state: state,
            child: AppShell(child: child),
          ),
          routes: [
            GoRoute(
              name: 'home',
              path: ApplicationRoutesConstants.home,
              pageBuilder: (context, state) =>
                  appTransitionPage(state: state, type: AppPageTransitionType.fade, child: const HomePlaceholderPage()),
            ),
            ...SettingsFeatureRoutes.routes,
          ],
        ),
      ],
    );
  }
}
