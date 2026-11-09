import 'package:ai_engineering_bazaar/app/dev_console/content_gallery_page.dart';
import 'package:ai_engineering_bazaar/app/dev_console/dev_console_overlay.dart';
import 'package:ai_engineering_bazaar/app/router/app_root_page.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/app/router/not_found_page.dart';
import 'package:ai_engineering_bazaar/app/router/route_placeholder.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/catalog_page.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/level_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/quiz_panel.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/module_reader_page.dart';
import 'package:ai_engineering_bazaar/features/settings/navigation/settings_routes.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AppRouterFactory {
  const AppRouterFactory({this.initialLocation = BazaarPaths.catalogEngineers});

  /// Where the router starts.
  final String initialLocation;

  static final _log = AppLogger.getLogger('AppRouterFactory');

  /// A location to start at instead of [initialLocation], from `--dart-define=DEBUG_START_ROUTE`; honoured in debug
  /// and profile builds (the device spike and the performance run open a page without taps), never in release.
  static const _debugStartRoute = String.fromEnvironment('DEBUG_START_ROUTE');

  GoRouter create() {
    return GoRouter(
      initialLocation: !kReleaseMode && _debugStartRoute.isNotEmpty ? _debugStartRoute : initialLocation,
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
      // The web's routes (Decision A9): the For Engineers catalog is `/` (the web's `/sheets/`), the For Everyone one
      // `/everyone/sheets`; `/dashboard`, `/path` and `/report` are gone on the web and have no route, and there are
      // no moved-address forwards. go_router 18.1.1 strips a trailing slash from every location before matching
      // (`configuration.dart:243-256`, `parser.dart:102-106`), so no slash redirect is needed.
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => appPlatformPage(
            state: state,
            child: DevConsoleShortcut(
              child: BazaarShell(location: state.uri.path, child: child),
            ),
          ),
          routes: [
            _page('catalog', BazaarPaths.catalogEngineers, const CatalogPage(track: Track.engineers)),
            _page('catalogEveryone', BazaarPaths.catalogEveryone, const CatalogPage(track: Track.everyone)),
            _pageOf(
              'level',
              '/sheets/:level',
              (state) => LevelPage(track: Track.engineers, level: state.pathParameters['level']!),
            ),
            _pageOf(
              'levelEveryone',
              '/everyone/sheets/:level',
              (state) => LevelPage(track: Track.everyone, level: state.pathParameters['level']!),
            ),
            _pageOf('module', '/courses/:level/:module', (state) => _reader(state, Track.engineers)),
            _pageOf('moduleEveryone', '/everyone/courses/:level/:module', (state) => _reader(state, Track.everyone)),
            _page('progress', BazaarPaths.progress, const RoutePlaceholder()),
            ...SettingsFeatureRoutes.routes,
            // The device spike's gallery (spec 3.6.4), in debug builds only.
            if (kDebugMode) _page('debugGallery', '/debug/gallery', const ContentGalleryPage()),
          ],
        ),
        // The web's catalog paths that are not pages of their own here.
        GoRoute(path: '/sheets', redirect: (_, _) => BazaarPaths.catalogEngineers),
        GoRoute(path: '/courses', redirect: (_, _) => BazaarPaths.catalogEngineers),
        GoRoute(
          path: '/courses/:level',
          redirect: (_, state) => BazaarPaths.level(Track.engineers, state.pathParameters['level']!),
        ),
      ],
    );
  }

  /// The reader of the module the path names, scrolled to the heading a module link passes as `extra`, with the quiz
  /// feature's panel in its quiz slot (Decision A38). For Everyone documents carry no quiz, so their slot stays empty.
  static Widget _reader(GoRouterState state, Track track) => ModuleReaderPage(
    moduleKey: '${state.pathParameters['level']}/${state.pathParameters['module']}',
    track: track,
    fragment: state.extra as String?,
    quizBuilder: buildQuizPanel,
  );

  static GoRoute _page(String name, String path, Widget child) => _pageOf(name, path, (_) => child);

  /// A route whose page reads the [GoRouterState], for its path parameters.
  static GoRoute _pageOf(String name, String path, Widget Function(GoRouterState state) build) => GoRoute(
    name: name,
    path: path,
    pageBuilder: (context, state) => appTransitionPage(context: context, state: state, child: build(state)),
  );
}
