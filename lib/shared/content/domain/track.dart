/// The two tracks of the course, by the id the bundle uses.
///
/// Track ids are an open set in the bundle contract: an id this app does not know is ignored (Decision A23).
enum Track {
  engineers('engineers'),
  everyone('everyone');

  const Track(this.id);

  /// The id in the bundle (`tracks[].id`, the keys of a module's `tracks`).
  final String id;

  /// The track with [id], or null for a track this app does not know.
  static Track? fromId(String id) {
    for (final track in values) {
      if (track.id == id) return track;
    }
    return null;
  }

  /// The other track.
  Track get other => switch (this) {
    Track.engineers => Track.everyone,
    Track.everyone => Track.engineers,
  };
}
