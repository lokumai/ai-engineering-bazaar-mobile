import 'package:ai_engineering_bazaar/shared/language/language_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The language of the interface and of the documents the reader opens (plan 1Q), as a code: `en`, `tr` or `fa`.
///
/// Before the reader chooses one in Settings it is the device's language when the app has it, English otherwise. The
/// choice is kept by the [ILanguageStore], on this device and never in the record. A module with no document in the
/// language opens in English.
final class LanguageCubit extends Cubit<String> {
  LanguageCubit({this._store = const MemoryLanguageStore(), String initial = english})
    : super(supported.contains(initial) ? initial : english);

  final ILanguageStore _store;

  /// The bundle's source language.
  static const english = 'en';

  /// The languages the interface is written in, the bundle's source language first (`index.json`'s `translations`).
  static const supported = [english, 'tr', 'fa'];

  /// Each language's own name, the same in every interface language so a reader can find theirs.
  static const names = {english: 'English', 'tr': 'Türkçe', 'fa': 'فارسی'};

  /// Reads the chosen language, if one was chosen, and makes it the current language.
  Future<void> load() async {
    final chosen = await _store.chosen();
    if (chosen != null && supported.contains(chosen) && !isClosed && chosen != state) emit(chosen);
  }

  /// Makes [language] the current language and keeps it as the reader's choice.
  Future<void> choose(String language) async {
    if (!supported.contains(language)) throw ArgumentError.value(language, 'language', 'not supported');
    if (language != state) emit(language);
    // One choice is written at a time, in the order made: the store clears the other choices before it keeps this one,
    // so two quick choices written at once could leave both kept, and the next start take the wrong one.
    final previous = _saving;
    final saving = _saving = () async {
      // A write that failed was logged by the store; the next one still runs.
      await previous.catchError((Object _) {});
      await _store.choose(language);
    }();
    await saving;
  }

  /// The write of the last choice, which the next one waits for.
  Future<void> _saving = Future<void>.value();
}
