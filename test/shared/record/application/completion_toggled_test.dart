import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/application/completion_toggled.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/content_builders.dart';

void main() {
  final both = testModule(
    key: 'alpha/both',
    tracks: {
      Track.engineers: testModuleTrack(
        revision: const Revision(hash: 'aaa1111', date: '2026-11-01'),
      ),
      Track.everyone: testModuleTrack(
        revision: const Revision(hash: 'bbb2222', date: '2026-11-02'),
      ),
    },
  );
  final engineersOnly = testModule(
    key: 'alpha/engineers',
    number: 2,
    tracks: {
      Track.engineers: testModuleTrack(),
      Track.everyone: testModuleTrack(drawn: false, docs: const {}),
    },
  );
  final index = testIndex(modules: [both, engineersOnly]);

  test('For Engineers carries the written For Everyone version with its revision (plan 1V)', () {
    final event = completionToggled(index, 'alpha/both', Track.engineers, revision: 'aaa1111');

    expect((event.key, event.revision, event.track), ('alpha/both', 'aaa1111', Track.engineers));
    expect(event.everyone?.revision, 'bbb2222');
  });

  test('with no revision from the caller, the For Everyone one is none too (A35)', () {
    final event = completionToggled(index, 'alpha/both', Track.engineers, revision: null);

    expect(event.everyone, isNotNull);
    expect(event.everyone!.revision, isNull);
  });

  test('a For Everyone version not written is not carried', () {
    expect(completionToggled(index, 'alpha/engineers', Track.engineers, revision: null).everyone, isNull);
  });

  test('For Everyone carries nothing', () {
    expect(completionToggled(index, 'alpha/both', Track.everyone, revision: 'bbb2222').everyone, isNull);
  });
}
