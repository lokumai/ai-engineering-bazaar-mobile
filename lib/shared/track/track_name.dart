import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// [track]'s name in the interface language (plan 1Q). The bundle names each track in English only
/// (`index.json`'s `tracks`), so the interface names it from its own strings.
String trackName(S s, Track track) => switch (track) {
  Track.engineers => s.track_engineers,
  Track.everyone => s.track_everyone,
};
