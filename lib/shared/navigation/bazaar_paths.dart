import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// The app's route paths and the track switch mapping.
///
/// Mirrors the web's `catalogRoute`, `moduleRoute` and `trackOfPath` (`src/lib/tracks.ts`) and the track switch's
/// `targetsFor` (`src/components/shell/TrackSwitch.tsx`) in the web repo.
/// The For Engineers catalog root is `/` (the web's `/sheets/`, Decision A9); paths carry no trailing slash.
///
/// The web also accepts shapes the app never routes inside the shell (`/courses`, `/everyone`, `/sheets/<l>/<m>`, a
/// module path with extra segments); the app redirects them or shows the not-found page, where no switch is drawn, so
/// [trackOf] and [trackSwitchTarget] return null for them.
abstract final class BazaarPaths {
  static const catalogEngineers = '/';
  static const catalogEveryone = '/everyone/sheets';
  static const progress = '/profile';
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

  /// The track a catalog or module page belongs to; null for every other location.
  static Track? trackOf(String location) => _parse(location)?.track;

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

  /// The seven shapes of a track page, split on `/` with empty segments dropped as the web does.
  static _TrackPage? _parse(String location) {
    final segments = location.split('/').where((segment) => segment.isNotEmpty).toList();
    final track = segments.isNotEmpty && segments.first == _everyone ? Track.everyone : Track.engineers;
    final rest = track == Track.everyone ? segments.sublist(1) : segments;
    return switch (rest) {
      [] when track == Track.engineers => _CatalogPage(track),
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
