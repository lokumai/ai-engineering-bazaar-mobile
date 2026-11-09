import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Store implements ILanguageStore {
  _Store([this.kept]);

  String? kept;

  @override
  Future<String?> chosen() async => kept;

  @override
  Future<void> choose(String language) async => kept = language;
}

void main() {
  test('starts in English', () => expect(LanguageCubit().state, 'en'));
  test('starts in the device language when the app has it', () => expect(LanguageCubit(initial: 'tr').state, 'tr'));
  test('starts in English when the device language is not one the app has', () {
    expect(LanguageCubit(initial: 'de').state, 'en');
  });

  blocTest<LanguageCubit, String>(
    'load makes the kept choice current',
    build: () => LanguageCubit(store: _Store('fa')),
    act: (c) => c.load(),
    expect: () => ['fa'],
  );
  blocTest<LanguageCubit, String>(
    'load with no choice keeps the starting language',
    build: () => LanguageCubit(store: _Store(), initial: 'tr'),
    act: (c) => c.load(),
    expect: () => <String>[],
  );

  test('choose makes the language current and keeps it', () async {
    final store = _Store();
    final cubit = LanguageCubit(store: store);
    addTearDown(cubit.close);

    await cubit.choose('tr');

    expect(cubit.state, 'tr');
    expect(store.kept, 'tr');
  });

  test('choose refuses a language the app does not have', () {
    expect(() => LanguageCubit().choose('de'), throwsArgumentError);
  });
}
