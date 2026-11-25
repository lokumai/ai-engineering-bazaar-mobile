import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';

/// A link to the website that the app opens itself (plan 17.2): a module, a level or the catalog of a track, or a
/// progress transfer. The phone hands the app such a link when the site's app link files name the app (Android's
/// `assetlinks.json`, iOS's `apple-app-site-association`), or through the app's own scheme, which the site's transfer
/// page offers as "Open in the Bazaar app".
///
/// The site's addresses (its `tracks.ts`): For Engineers has no prefix, For Everyone `/everyone`, and a language other
/// than English comes first (`/tr/everyone/courses/...`). The app opens a module in the language the reader chose in
/// the app, so the language of a link is read past and not followed.
sealed class SiteLink extends Equatable {
  const SiteLink();

  /// The link [uri] names, or null when it is not one the app opens: another host, another scheme or a page the app
  /// has no place for.
  ///
  /// [site] is the site's address (the app's content base URL); a link to its host over https is read, and so is
  /// [scheme] with the host `transfer`.
  static SiteLink? parse(Uri uri, Uri site) {
    if (uri.scheme == scheme) {
      return uri.host == transferSegment ? _transfer(uri) : null;
    }
    if (uri.scheme != 'https' || uri.host != site.host) return null;
    final List<String> path;
    try {
      path = uri.pathSegments;
    } on FormatException {
      // An escape that is not UTF-8 in the path, as an old Latin-1 address: none of the site's pages (review 5,
      // finding 1).
      return null;
    }
    var segments = path.where((segment) => segment.isNotEmpty).toList();
    if (segments case [final language, ...final rest] when languages.contains(language)) segments = rest;
    final track = segments.firstOrNull == everyoneSegment ? Track.everyone : Track.engineers;
    if (track == Track.everyone) segments = segments.sublist(1);
    return switch (segments) {
      [transferSegment] when track == Track.engineers => _transfer(uri),
      ['sheets'] || ['courses'] => SiteCatalog(track),
      ['sheets', final level] || ['courses', final level] when _slug.hasMatch(level) => SiteLevel(track, level),
      ['courses', final level, final module] when _slug.hasMatch(level) && _slug.hasMatch(module) => SiteModule(
        track,
        '$level/$module',
        fragment: _heading(uri),
      ),
      _ => null,
    };
  }

  /// A level's or a module's name as the site writes it. A segment decoded to a slash, a question mark or a stray escape
  /// would change the route it becomes, so it is no link (review 6, finding 13).
  static final _slug = RegExp(r'^[a-z0-9][a-z0-9-]*$');

  /// The app's own scheme, which only the site's transfer page uses.
  static const scheme = 'aibazaar';

  /// The languages the site writes before a page's address.
  static const languages = {'tr', 'fa'};

  /// The segment of the transfer page, and the host of the app's own scheme.
  static const transferSegment = 'transfer';

  /// The segment of the For Everyone pages.
  static const everyoneSegment = 'everyone';

  /// The heading a module link names after `#`, as the site writes its ids; anything else opens the module at its top
  /// (the release build's walk-through, review 11: the heading was dropped).
  static String? _heading(Uri uri) {
    if (!uri.hasFragment) return null;
    final String id;
    try {
      id = Uri.decodeComponent(uri.fragment);
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
    return _headingId.hasMatch(id) ? id : null;
  }

  static final _headingId = RegExp(r'^[\p{L}\p{N}_-]{1,120}$', unicode: true);

  static SiteLink? _transfer(Uri uri) {
    final String? payload;
    try {
      payload = Uri.splitQueryString(uri.fragment)['t'];
    } on FormatException {
      // An escape that is not UTF-8, as a link cut short: not a transfer (review 4, finding 4).
      return null;
    }
    return payload == null || payload.isEmpty ? null : SiteTransfer(payload);
  }
}

/// The catalog of [track].
final class SiteCatalog extends SiteLink {
  const SiteCatalog(this.track);

  final Track track;

  @override
  List<Object?> get props => [track];
}

/// The page of [level] in [track].
final class SiteLevel extends SiteLink {
  const SiteLevel(this.track, this.level);

  final Track track;
  final String level;

  @override
  List<Object?> get props => [track, level];
}

/// The module [moduleKey] (`<level>/<module>`) in [track], at the heading [fragment] when the link names one.
final class SiteModule extends SiteLink {
  const SiteModule(this.track, this.moduleKey, {this.fragment});

  final Track track;
  final String moduleKey;
  final String? fragment;

  @override
  List<Object?> get props => [track, moduleKey, fragment];
}

/// A progress transfer, its [payload] as the link carries it (`#t=`).
final class SiteTransfer extends SiteLink {
  const SiteTransfer(this.payload);

  final String payload;

  @override
  List<Object?> get props => [payload];
}

/// The site's transfer page carrying [payload]: the link Settings sends to the website.
Uri transferLink(Uri site, String payload) => site.resolve('${SiteLink.transferSegment}/#t=$payload');
