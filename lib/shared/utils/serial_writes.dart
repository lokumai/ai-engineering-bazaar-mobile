/// Writes that run one at a time, in the order asked: a choice's store clears the others before it keeps its own, so
/// two quick choices written at once could leave both kept. A write that failed fails its own caller only; the next
/// still runs.
///
/// One helper for every store-backed cubit, where six had their own copy with two error semantics (review 11,
/// architecture 8).
final class SerialWrites {
  Future<void> _last = Future<void>.value();

  /// Runs [write] once the writes asked before it are done, failed or not.
  Future<void> run(Future<void> Function() write) {
    final previous = _last;
    return _last = () async {
      try {
        await previous;
      } on Object {
        // Its own caller was told; this write still runs.
      }
      await write();
    }();
  }
}
