import 'package:ai_engineering_bazaar/features/catalog/application/catalog_fold_cubit.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an untouched track opens the next level, and nothing when every module is complete', () {
    final fold = CatalogFoldCubit();
    addTearDown(fold.close);

    expect(fold.openIn(Track.engineers, 'alpha'), {'alpha'});
    expect(fold.openIn(Track.engineers, 'beta'), {'beta'}, reason: 'it follows the next module');
    expect(fold.openIn(Track.engineers, null), isEmpty);
  });

  test('a toggle fixes the track from what was showing, and leaves the other track untouched', () {
    final fold = CatalogFoldCubit();
    addTearDown(fold.close);

    fold.toggle(Track.engineers, 'beta', 'alpha');
    expect(fold.openIn(Track.engineers, 'gamma'), {'alpha', 'beta'}, reason: 'no longer follows the next module');
    fold.toggle(Track.engineers, 'alpha', 'gamma');
    expect(fold.openIn(Track.engineers, 'gamma'), {'beta'});
    expect(fold.openIn(Track.everyone, 'gamma'), {'gamma'});
  });
}
