/// Where a module page opens, passed as the route's `extra`: the heading to scroll to, and the words searched in the
/// catalog, which the reader marks (plan 7.1). A module link passes the heading alone, as a plain string.
final class ReaderTarget {
  const ReaderTarget({this.fragment, this.query, this.visit = false});

  /// The id of the heading to open at.
  final String? fragment;

  /// The words searched, as typed.
  final String? query;

  /// Whether the module is of the other track, opened from a search that found nothing in the reader's track (plan
  /// 12.7): the shell leaves the reader's track as it is, as it would not for a link to the other track.
  final bool visit;

  /// The target an `extra` names: a [ReaderTarget], a heading id, or nothing.
  static ReaderTarget of(Object? extra) => switch (extra) {
    final ReaderTarget target => target,
    final String fragment => ReaderTarget(fragment: fragment),
    _ => const ReaderTarget(),
  };
}
