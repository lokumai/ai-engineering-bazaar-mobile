import 'dart:math' as math;

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

/// The pocket model on Home (plan 9.2): a tiny model the reader trains with tokens when bored. It is a toy that borrows
/// the course's ideas, not a model: the tokens it was fed decide its level and the loss its training curve shows, and
/// both are arithmetic over one count.
///
/// It keeps three facts, which the device stores apart from the record: the tokens fed, when it was last fed, and how
/// many times in a row it was fed within [overfitWindow] (a burst), which makes it overfit.
final class PocketModel extends Equatable {
  const PocketModel({required this.tokens, this.lastFed, this.burst = const []});

  /// A model never fed.
  static const PocketModel fresh = PocketModel(tokens: 0);

  /// The tokens one feed gives.
  static const int feedTokens = 8;

  /// The tokens each level starts at, from level 0.
  static const List<int> levels = [0, 24, 80, 180, 360, 640, 1000, 1600];

  /// Feeds this close together count toward a burst.
  static const Duration overfitWindow = Duration(seconds: 12);

  /// The feeds in a burst that make it overfit.
  static const int overfitFeeds = 7;

  /// How long an overfit model repeats itself before it recovers.
  static const Duration overfitRest = Duration(seconds: 20);

  /// Since when not fed it is hungry, and asleep.
  static const Duration hungerAfter = Duration(hours: 3);
  static const Duration sleepAfter = Duration(hours: 10);

  final int tokens;

  /// When it was last fed; null before the first feed.
  final DateTime? lastFed;

  /// The moments of the feeds in the current burst, the latest last.
  final List<DateTime> burst;

  /// The level its [tokens] reach, from 0.
  int get level {
    var reached = 0;
    for (var i = 0; i < levels.length; i++) {
      if (tokens >= levels[i]) reached = i;
    }
    return reached;
  }

  /// The tokens to the next level, or null at the top.
  int? get toNext => level + 1 < levels.length ? levels[level + 1] - tokens : null;

  /// How far it is from this level to the next, 0 to 1; 1 at the top.
  double get progress {
    final next = level + 1 < levels.length ? levels[level + 1] : null;
    if (next == null) return 1;
    return (tokens - levels[level]) / (next - levels[level]);
  }

  /// The loss after [tokens] of training: it falls fast, then slowly, with a little noise, as a training curve does.
  static double lossAt(int tokens) {
    final noise = math.sin(tokens * 12.9898) * 0.04;
    return math.max(0.08, 3.2 * math.exp(-tokens / 260) + 0.14 + noise * math.exp(-tokens / 900));
  }

  /// Its loss now.
  double get loss => lossAt(tokens);

  /// The training curve, [points] losses from the first token to now; empty before the first feed.
  List<double> curve({int points = 24}) {
    if (tokens == 0) return const [];
    return [for (var i = 0; i < points; i++) lossAt((tokens * i / (points - 1)).round())];
  }

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
    if (overfitAt(now)) return PocketModel(tokens: tokens, lastFed: lastFed, burst: kept);
    return PocketModel(tokens: tokens + feedTokens, lastFed: now, burst: kept);
  }

  /// Rested: the burst forgotten.
  PocketModel rested() => PocketModel(tokens: tokens, lastFed: lastFed);

  @override
  List<Object?> get props => [tokens, lastFed, burst];
}
