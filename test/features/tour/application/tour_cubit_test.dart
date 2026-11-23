import 'dart:async';

import 'package:ai_engineering_bazaar/features/tour/application/tour_cubit.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_page.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing is due before it is loaded, nor for a reader never offered it', () async {
    final cubit = TourCubit(store: MemoryTourStore());
    expect(cubit.state, isNull);
    expect(cubit.due(TourPage.home), isFalse);
    await cubit.load();
    expect(cubit.state, const TourRecord());
    expect(TourPage.values.where(cubit.due), isEmpty);
  });

  test('offered, it asks; said yes, every page is due until shown, and all of it is kept', () async {
    final store = MemoryTourStore();
    final cubit = TourCubit(store: store);
    await cubit.load();

    await cubit.offer();
    expect(store.kept, const TourRecord(asking: true));
    expect(cubit.due(TourPage.home), isFalse, reason: 'it asks first');

    await cubit.accept();
    expect(store.kept, const TourRecord(guiding: true));
    expect(TourPage.values.where(cubit.due), TourPage.values);

    await cubit.shown(TourPage.home);
    await cubit.shown(TourPage.practice);
    expect(store.kept.seen, {'home', 'practice'});
    expect(TourPage.values.where(cubit.due), [TourPage.catalog, TourPage.caravan, TourPage.settings]);
  });

  test('said no, nothing is due', () async {
    final cubit = TourCubit(store: MemoryTourStore(const TourRecord(asking: true)));
    await cubit.load();
    await cubit.decline();
    expect(cubit.state, const TourRecord());
    expect(TourPage.values.where(cubit.due), isEmpty);
  });

  test('replayed, every page is due again', () async {
    final cubit = TourCubit(store: MemoryTourStore(const TourRecord(guiding: true, seen: {'home', 'catalog'})));
    await cubit.load();
    await cubit.replay();
    expect(TourPage.values.where(cubit.due), TourPage.values);
  });

  test('a choice made before the store answers is not undone by its answer', () async {
    final cubit = TourCubit(store: MemoryTourStore());
    final loading = cubit.load();
    await cubit.offer();
    await loading;
    expect(cubit.state, const TourRecord(asking: true));
  });

  test('each tab\'s first page is a page of the tour, and nothing else is', () {
    expect(TourPage.at('/'), TourPage.home);
    expect(TourPage.at('/sheets'), TourPage.catalog);
    expect(TourPage.at('/everyone/sheets'), TourPage.catalog);
    expect(TourPage.at('/caravan'), TourPage.caravan);
    expect(TourPage.at('/practice'), TourPage.practice);
    expect(TourPage.at('/settings'), TourPage.settings);
    expect(TourPage.at('/sheets/alpha'), isNull);
    expect(TourPage.at('/courses/alpha/first'), isNull);
  });

  // Review 8, finding 16: the saves ran side by side over several files, so a slower earlier one could land after a
  // later one.
  test('saves one at a time, in order, the last record last', () async {
    final store = _SlowStore();
    final cubit = TourCubit(store: store);
    await cubit.load();

    final saves = [cubit.offer(), cubit.accept(), cubit.shown(TourPage.home)];
    await Future<void>.delayed(Duration.zero);
    expect(store.started, [const TourRecord(asking: true)], reason: 'one at a time');
    while (store.waiting.isNotEmpty) {
      store.waiting.removeAt(0).complete();
      await Future<void>.delayed(Duration.zero);
    }
    await Future.wait(saves);
    expect(store.started, [
      const TourRecord(asking: true),
      const TourRecord(guiding: true),
      const TourRecord(guiding: true, seen: {'home'}),
    ]);
  });

  test('a save that failed does not stop the next', () async {
    final store = _SlowStore();
    final cubit = TourCubit(store: store);
    await cubit.load();

    final first = cubit.offer();
    final second = cubit.accept();
    await Future<void>.delayed(Duration.zero);
    store.waiting.removeAt(0).completeError(StateError('disk'));
    await expectLater(first, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    store.waiting.removeAt(0).complete();
    await second;
    expect(store.started.last, const TourRecord(guiding: true));
  });
}

/// A store whose saves wait until the test lets each one end.
final class _SlowStore implements ITourStore {
  final started = <TourRecord>[];
  final waiting = <Completer<void>>[];

  @override
  Future<TourRecord> load() async => const TourRecord();

  @override
  Future<void> save(TourRecord record) {
    started.add(record);
    final done = Completer<void>();
    waiting.add(done);
    return done.future;
  }
}
