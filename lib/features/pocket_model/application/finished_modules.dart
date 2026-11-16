import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/curriculum_for.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';

/// The modules the reader completed in [track] that [model] has not read yet, by their number (plan 9.6): what the
/// pocket model can read next, and what its button counts.
List<String> finishedUnread({
  required BundleIndex index,
  required RecordData record,
  required Track track,
  required PocketModel model,
}) {
  final view = trackView(record, track);
  final finished = [
    for (final fact in curriculumFor(index, track).modules)
      if (isSigned(fact, view) && !model.hasRead(fact.slug)) fact,
  ]..sort((a, b) => a.number.compareTo(b.number));
  return [for (final fact in finished) fact.slug];
}
