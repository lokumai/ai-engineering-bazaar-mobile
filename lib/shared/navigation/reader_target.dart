/// Where a module page opens, passed as the route's `extra`: the heading to scroll to, and the words searched in the
/// catalog, which the reader marks (plan 7.1). A module link passes the heading alone, as a plain string.
final class ReaderTarget {
  const ReaderTarget({this.fragment, this.query});

  /// The id of the heading to open at.
  final String? fragment;

  /// The words searched, as typed.
  final String? query;

  /// The target an `extra` names: a [ReaderTarget], a heading id, or nothing.
  static ReaderTarget of(Object? extra) => switch (extra) {
    final ReaderTarget target => target,
    final String fragment => ReaderTarget(fragment: fragment),
    _ => const ReaderTarget(),
  };
}
