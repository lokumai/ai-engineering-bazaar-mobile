import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// The app's route paths and the track switch mapping.
///
/// Mirrors the web's `catalogRoute`, `moduleRoute` and `trackOfPath` (`src/lib/tracks.ts`) and the track switch's
/// `targetsFor` (`src/components/shell/TrackSwitch.tsx`) in the web repo.
/// Home is `/` and the For Engineers catalog root is `/sheets`, as on the web (Decision A9 put the catalog at `/` while
/// the app had no Home; the redesign adds it, plan Phase 1C). Paths carry no trailing slash.
///
/// The web also accepts shapes the app never routes inside the shell (`/courses`, `/everyone`, `/sheets/<l>/<m>`, a
/// module path with extra segments); the app redirects them or shows the not-found page, where no switch is drawn, so
/// [trackOf] and [trackSwitchTarget] return null for them.
abstract final class BazaarPaths {
  static const home = '/';
  static const catalogEngineers = '/sheets';
  static const catalogEveryone = '/everyone/sheets';
  static const quizzes = '/quiz';

  /// The Caravan, the web's trends timeline (`/caravan/`); under maintenance in the app until the bundle carries it
  /// (plan 3.1).
  static const caravan = '/caravan';

  static const settings = '/settings';

  static const _everyone = 'everyone';
  static const _sheets = 'sheets';
  static const _courses = 'courses';

  /// The catalog root of [track].
  static String catalog(Track track) => switch (track) {
    Track.engineers => catalogEngineers,
    Track.everyone => catalogEveryone,
  };

  /// The page of one [level] in [track]: `/sheets/<level>` or `/everyone/sheets/<level>`.
  static String level(Track track, String level) => '${_prefix(track)}/$_sheets/$level';

  /// The reader page of the module [key] in [track]: `/courses/<key>` or `/everyone/courses/<key>`.
  static String module(Track track, String key) => '${_prefix(track)}/$_courses/$key';

  /// The quiz of the module [key] full screen, `/quiz/<key>` (plan 1AC; the web has no quiz page, A9).
  static String quiz(String key) => '$quizzes/$key';

  /// The track a catalog or module page belongs to; null for every other location, Home included.
  static Track? trackOf(String location) => _parse(location)?.track;

  /// The level slug of a level page; null for every other location.
  static String? levelOf(String location) => switch (_parse(location)) {
    _LevelPage(:final slug) => slug,
    _ => null,
  };

  /// The module key, `<level>/<module>`, of a module page; null for every other location.
  static String? moduleOf(String location) => switch (_parse(location)) {
    _ModulePage(:final slug, :final name) => '$slug/$name',
    _ => null,
  };

  /// Where the track switch goes from [location] when [to] is chosen; null on a page of neither track.
  ///
  /// A module page always maps to the other track's module page, written or not, as on the web.
  static String? trackSwitchTarget(String location, Track to) => switch (_parse(location)) {
    null => null,
    _CatalogPage() => catalog(to),
    _LevelPage(:final slug) => level(to, slug),
    _ModulePage(:final slug, :final name) => module(to, '$slug/$name'),
  };

  static String _prefix(Track track) => switch (track) {
    Track.engineers => '',
    Track.everyone => '/$_everyone',
  };

  /// The six shapes of a track page, split on `/` with empty segments dropped as the web does.
  static _TrackPage? _parse(String location) {
    final segments = location.split('/').where((segment) => segment.isNotEmpty).toList();
    final track = segments.isNotEmpty && segments.first == _everyone ? Track.everyone : Track.engineers;
    final rest = track == Track.everyone ? segments.sublist(1) : segments;
    return switch (rest) {
      [_sheets] => _CatalogPage(track),
      [_sheets, final slug] => _LevelPage(track, slug),
      [_courses, final slug, final name] => _ModulePage(track, slug, name),
      _ => null,
    };
  }
}

sealed class _TrackPage {
  const _TrackPage(this.track);

  final Track track;
}

final class _CatalogPage extends _TrackPage {
  const _CatalogPage(super.track);
}

final class _LevelPage extends _TrackPage {
  const _LevelPage(super.track, this.slug);

  final String slug;
}

final class _ModulePage extends _TrackPage {
  const _ModulePage(super.track, this.slug, this.name);

  final String slug;
  final String name;
}
