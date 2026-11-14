import 'package:ai_engineering_bazaar/features/pocket_model/domain/corpus/chat.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/corpus/en.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/corpus/fa.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/corpus/tr.dart';

/// What the pocket model reads: short sentences on the course's ideas, in the app's three languages, written for the
/// toy (not taken from the course), one file a language under `corpus/`. [training] is read in order, a feed at a
/// time, and again from the top once it is all read; [heldOut] is never read, and the loss is measured on it, as a
/// model's is on text it never trained on.
///
/// The sentences share their words, so the model can join what it read into sentences it never read. None speaks as
/// a person, as the app's copy does not; the robot's own talk to the reader is [chat] (`corpus/chat.dart`).
abstract final class PocketCorpus {
  static List<String> training(String language) => switch (language) {
    'tr' => trTraining,
    'fa' => faTraining,
    _ => enTraining,
  };

  static List<String> heldOut(String language) => switch (language) {
    'tr' => trHeldOut,
    'fa' => faHeldOut,
    _ => enHeldOut,
  };

  /// What the robot says to the reader as a friend, by kind, each sentence with its tier (`corpus/chat.dart`).
  static Map<String, List<(int, String)>> chat(String language) => switch (language) {
    'tr' => trChat,
    'fa' => faChat,
    _ => enChat,
  };

  /// What it says before a sentence of a module it read, as one tells a friend.
  static List<String> leadIns(String language) => switch (language) {
    'tr' => trLeadIns,
    'fa' => faLeadIns,
    _ => enLeadIns,
  };
}
