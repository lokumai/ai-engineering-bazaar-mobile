import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:equatable/equatable.dart';

/// How the pocket model feels, from how long ago it was fed.
enum PocketMood {
  /// Never fed: it waits for its first tokens.
  newborn,

  /// Fed lately.
  content,

  /// Not fed for a while.
  hungry,

  /// Not fed for a long while: asleep until woken.
  asleep,
}

/// One course module the pocket model read (plan 9.6): its key, how many tokens of its own text it had read then, and
/// how many tokens the module gave.
final class PocketReading extends Equatable {
  const PocketReading({required this.key, required this.at, required this.tokens});

  /// The module key, `<level>/<module>`.
  final String key;
  final int at;
  final int tokens;

  @override
  List<Object?> get props => [key, at, tokens];
}

/// The pocket model (plan 9.2): a tiny model the reader trains with tokens when bored. The tokens it was fed and the
/// modules it read decide its level here, each module one level whatever its length ([level]); its language model ([TinyLm]) follows from the count of its
/// own text read and the modules it read.
///
/// It keeps four facts, which the device stores apart from the record: the tokens fed, the modules read, when it was
/// last fed, and how many times in a row it was fed within [overfitWindow] (a burst), which makes it overfit.
final class PocketModel extends Equatable {
  const PocketModel({required this.tokens, this.readings = const [], this.lastFed, this.burst = const []});

  /// A model never fed.
  static const PocketModel fresh = PocketModel(tokens: 0);

  /// The tokens one feed gives.
  static const int feedTokens = 8;

  /// The tokens fed that each level feeds give starts at, from level 0: feeds alone reach level [feedLevels].
  static const List<int> levels = [0, 24, 80, 180, 360, 640, 1000, 1600];

  /// The highest level feeds alone reach; its text is longer than the tokens it starts at.
  static const int feedLevels = 7;

  /// Feeds this close together count toward a burst.
  static const Duration overfitWindow = Duration(seconds: 12);

  /// The feeds in a burst that make it overfit.
  static const int overfitFeeds = 7;

  /// How long an overfit model repeats itself before it recovers.
  static const Duration overfitRest = Duration(seconds: 20);

  /// Since when not fed it is hungry, and asleep.
  static const Duration hungerAfter = Duration(hours: 3);
  static const Duration sleepAfter = Duration(hours: 10);

  /// The tokens of its own text it was fed.
  final int tokens;

  /// The modules it read, in the order read.
  final List<PocketReading> readings;

  /// Every token it took in: its text's and the modules'.
  int get total => tokens + readings.fold(0, (sum, reading) => sum + reading.tokens);

  /// When it was last fed; null before the first feed.
  final DateTime? lastFed;

  /// The moments of the feeds in the current burst, the latest last.
  final List<DateTime> burst;

  /// Its level, from 0: the level its feeds reach ([fedLevel]) and one for each module it read (the owner, 2026-11-14:
  /// a module of a few thousand tokens had made it jump seven levels at once).
  int get level => fedLevel + readings.length;

  /// The level its feeds alone reach, from 0 to [feedLevels].
  int get fedLevel {
    var reached = 0;
    for (var i = 0; i < levels.length; i++) {
      if (tokens >= levels[i]) reached = i;
    }
    return reached;
  }

  /// The tokens to feed to the next level, or null when feeds take it no higher and only a module does.
  int? get toNext => fedLevel < feedLevels ? levels[fedLevel + 1] - tokens : null;

  /// How far its feeds are from this level to the next, 0 to 1; 1 once feeds take it no higher.
  double get progress {
    if (fedLevel >= feedLevels) return 1;
    return (tokens - levels[fedLevel]) / (levels[fedLevel + 1] - levels[fedLevel]);
  }

  /// Where on its training curve it reached each level, in tokens of everything it took in ([total]), in order: each
  /// level its feeds reached, among the modules it read, and the end of each module.
  List<int> get levelMarks {
    final marks = <int>[];
    var read = 0;
    var next = 0;
    void readUpTo(int fed) {
      while (next < readings.length && readings[next].at < fed) {
        read += readings[next].tokens;
        marks.add(readings[next].at + read);
        next++;
      }
    }

    for (final start in levels.skip(1)) {
      if (start > tokens) break;
      readUpTo(start);
      marks.add(start + read);
    }
    readUpTo(tokens + 1);
    return marks;
  }

  /// Whether it read the module [key].
  bool hasRead(String key) => readings.any((reading) => reading.key == key);

  /// It read the module [key], [count] tokens, at [now]: a feed as far as its hunger goes, and no burst.
  PocketModel readAt(String key, int count, DateTime now) => PocketModel(
    tokens: tokens,
    readings: [
      ...readings,
      PocketReading(key: key, at: tokens, tokens: count),
    ],
    lastFed: now,
    burst: burst,
  );

  /// Whether it is overfit at [now]: fed [overfitFeeds] times in a burst, less than [overfitRest] ago.
  bool overfitAt(DateTime now) => burst.length >= overfitFeeds && now.difference(burst.last) < overfitRest;

  /// How it feels at [now].
  PocketMood moodAt(DateTime now) {
    final fed = lastFed;
    if (fed == null) return PocketMood.newborn;
    final since = now.difference(fed);
    if (since >= sleepAfter) return PocketMood.asleep;
    if (since >= hungerAfter) return PocketMood.hungry;
    return PocketMood.content;
  }

  /// Fed at [now]: [feedTokens] more tokens, unless it is overfit, when it takes none and only its burst goes on.
  PocketModel fedAt(DateTime now) {
    final recent = [
      for (final moment in burst)
        if (now.difference(moment) < overfitWindow || overfitAt(now)) moment,
      now,
    ];
    final kept = recent.length > overfitFeeds + 2 ? recent.sublist(recent.length - overfitFeeds - 2) : recent;
    if (overfitAt(now)) return PocketModel(tokens: tokens, readings: readings, lastFed: lastFed, burst: kept);
    return PocketModel(tokens: tokens + feedTokens, readings: readings, lastFed: now, burst: kept);
  }

  /// Rested: the burst forgotten.
  PocketModel rested() => PocketModel(tokens: tokens, readings: readings, lastFed: lastFed);

  @override
  List<Object?> get props => [tokens, readings, lastFed, burst];
}
