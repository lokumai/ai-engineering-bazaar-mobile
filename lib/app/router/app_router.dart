import 'package:ai_engineering_bazaar/features/about/navigation/about_routes.dart';
import 'package:ai_engineering_bazaar/features/guide/navigation/guide_routes.dart';
import 'package:ai_engineering_bazaar/app/dev_console/content_gallery_page.dart';
import 'package:ai_engineering_bazaar/app/dev_console/dev_console_overlay.dart';
import 'package:ai_engineering_bazaar/app/router/app_root_page.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/app/router/not_found_page.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/catalog_page.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/pages/level_page.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/pages/home_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/quiz_list_page.dart';
import 'package:ai_engineering_bazaar/features/quiz/presentation/pages/quiz_page.dart';
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
  const AppRouterFactory({this.initialLocation = BazaarPaths.home, this.crashReports = false});

  /// Where the router starts.
  final String initialLocation;

  /// Whether this build sends crash reports, which Settings' privacy note then says (plan 3.4).
  final bool crashReports;

  static final _log = AppLogger.getLogger('AppRouterFactory');

  /// A location to start at instead of [initialLocation], from `--dart-define=DEBUG_START_ROUTE`; honoured in debug
  /// and profile builds (the device spike and the performance run open a page without taps), never in release.
  static const _debugStartRoute = String.fromEnvironment('DEBUG_START_ROUTE');

  GoRouter create() {
    return GoRouter(
      initialLocation: !kReleaseMode && _debugStartRoute.isNotEmpty ? _debugStartRoute : initialLocation,
      // No outside location picks the first page (owner decision 15, Decision A9): an Android intent's `route` extra
      // reaches the engine as the platform's default route even with deep linking off, and go_router 18.1.1 would
      // prefer it to initialLocation (`router.dart:621-639`).
      overridePlatformDefaultLocation: true,
      debugLogDiagnostics: true,
      errorPageBuilder: (context, state) {
        // The page tells the user in the app language; the router's own error, in English, goes to the log.
        _log.warn('No page for location {}: {}', [state.uri, state.error]);
        return appRootPage(
          state: state,
          // An error state has no route name or path, so the page is named after the not-found route.
          name: ApplicationRoutesConstants.notFound,
          child: const NotFoundPage(),
        );
      },
      // The web's routes (Decision A9): Home is `/`, the For Engineers catalog `/sheets` and the For Everyone one
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
            _page('home', BazaarPaths.home, const HomePage()),
            _page('catalog', BazaarPaths.catalogEngineers, const CatalogPage(track: Track.engineers)),
            _page('catalogEveryone', BazaarPaths.catalogEveryone, const CatalogPage(track: Track.everyone)),
            _pageOf('level', '/sheets/:level', (state) => _level(state, Track.engineers)),
            _pageOf('levelEveryone', '/everyone/sheets/:level', (state) => _level(state, Track.everyone)),
            _pageOf('module', '/courses/:level/:module', (state) => _reader(state, Track.engineers)),
            _pageOf('moduleEveryone', '/everyone/courses/:level/:module', (state) => _reader(state, Track.everyone)),
            // The Quiz tab in place of the progress page, whose cards moved to the catalog (plan 1AB, 1AC).
            _page('quizzes', BazaarPaths.quizzes, const QuizListPage()),
            // Decision A6: a phone cannot send Ctrl+Shift+D, so debug builds open the console from Settings.
            ...GuideFeatureRoutes.routes(),
            ...SettingsFeatureRoutes.routes(
              openDevConsole: kDebugMode ? DevConsoleOverlay.show : null,
              crashReports: crashReports,
            ),
            // The device spike's gallery (spec 3.6.4), in debug builds only.
            if (kDebugMode) _page('debugGallery', '/debug/gallery', const ContentGalleryPage()),
          ],
        ),
        // The story of the Bazaar, a film over the whole app with no bar and no navigation (plan 3.5).
        ...AboutFeatureRoutes.routes(),
        // A module's quiz full screen, over the shell, from the Quiz tab or Home's practice (plan 1AC, 1AD).
        _pageOf(
          'quiz',
          '${BazaarPaths.quizzes}/:level/:module',
          (state) => QuizPage(moduleKey: '${state.pathParameters['level']}/${state.pathParameters['module']}'),
        ),
        // The web's catalog paths that are not pages of their own here.
        GoRoute(path: '/courses', redirect: (_, _) => BazaarPaths.catalogEngineers),
        GoRoute(
          path: '/courses/:level',
          redirect: (_, state) => BazaarPaths.level(Track.engineers, state.pathParameters['level']!),
        ),
      ],
    );
  }

  /// The level page the path names. go_router keys the page by its pattern, so the page is keyed by its level: a level
  /// chip opens the other level with its own Status filter and closed descriptions, as the web remounts it.
  static Widget _level(GoRouterState state, Track track) {
    final level = state.pathParameters['level']!;
    return LevelPage(key: ValueKey(level), track: track, level: level);
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
