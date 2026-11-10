import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';

/// The toggle of [key]'s completion on [track], with [revision] as the caller has it (A35). On For Engineers it
/// carries the module's For Everyone version when [index] has it written, so completing one completes both (plan 1V);
/// the For Everyone revision goes with it where the caller passes a revision, and none where it passes none.
CompletionToggled completionToggled(BundleIndex index, String key, Track track, {required String? revision}) {
  final everyone = index.module(key)?.tracks[Track.everyone];
  return CompletionToggled(
    key: key,
    revision: revision,
    track: track,
    everyone: track == Track.engineers && (everyone?.drawn ?? false)
        ? EveryoneCompletion(revision: revision == null ? null : everyone?.revision?.hash)
        : null,
  );
}
