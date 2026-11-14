import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_corpus.dart';

/// A point of the training curve: the loss after [tokens] of training.
typedef LossPoint = ({int tokens, double loss});

/// The pocket model's language model: a real one, if a very small one. It reads [PocketCorpus.training] in order, a
/// feed at a time, counting which word follows one word and which follows two; it writes by drawing the next word from
/// those counts, as a large model draws from its probabilities.
///
/// - The next word's chance mixes what followed the last two words, what followed the last one, and how often the
///   word came at all (a trigram model with Witten-Bell smoothing), so it joins what it read into sentences it never
///   read.
/// - The temperature reshapes the chances before it draws: below [cold] it takes the likeliest word every time; hot,
///   the rare words rise, and it joins words it never saw together, which is its hallucination.
/// - Its loss is the mean surprise (negative log-likelihood, in nats) on [PocketCorpus.heldOut], sentences it never
///   reads: before it reads anything every word is as likely as any other, and the loss falls as it learns.
///
/// Its state follows from the number of tokens it read, so a kept count rebuilds it.
final class TinyLm {
  TinyLm(this.language)
    : _stream = [
        for (final sentence in PocketCorpus.training(language)) ...[...sentence.split(' '), end],
      ] {
    _vocabulary = {..._stream, for (final sentence in PocketCorpus.heldOut(language)) ...sentence.split(' ')}.length;
  }

  /// A model that has read [tokens] tokens.
  factory TinyLm.trained(String language, int tokens) => TinyLm(language)..trainTo(tokens);

  final String language;
  final List<String> _stream;
  late final int _vocabulary;

  /// The end of a sentence: a token the model learns to predict like any other, and stops at.
  static const end = '</s>';
  static const _start = '<s>';

  /// How much of the chance a writing model passes down to words that did not follow: a little, so it writes what
  /// it read and joins it only now and then, more as the temperature rises.
  static const _writingBackoff = 0.15;

  /// The add-k smoothing of the loss, so a word never read still has a chance.
  static const _k = 0.5;

  /// The longest thing it says.
  static const longest = 12;

  final Map<String, int> _once = {};
  final Map<String, Map<String, int>> _after1 = {};
  final Map<String, Map<String, int>> _after2 = {};
  final Map<String, int> _after1Total = {};
  final Map<String, int> _after2Total = {};
  int _total = 0;
  int _trained = 0;
  String _a = _start;
  String _b = _start;

  /// The tokens read so far.
  int get trained => _trained;

  /// The words it has read at least once.
  int get known => _once.length - (_once.containsKey(end) ? 1 : 0);

  /// The tokens of one pass over its text.
  int get epoch => _stream.length;

  /// Reads the next [count] tokens, from the top again after the last, and returns the words read.
  List<String> train(int count) {
    final read = <String>[];
    for (var i = 0; i < count; i++) {
      final word = _stream[_trained % _stream.length];
      _count(_a, _b, word);
      if (word == end) {
        _a = _start;
        _b = _start;
      } else {
        read.add(word);
        _a = _b;
        _b = word;
      }
      _trained++;
    }
    return read;
  }

  /// Reads on until it has read [tokens]; a model that has read more is left as it is.
  void trainTo(int tokens) {
    if (tokens > _trained) train(tokens - _trained);
  }

  void _count(String a, String b, String word) {
    _once[word] = (_once[word] ?? 0) + 1;
    _total++;
    (_after1[b] ??= {})[word] = (_after1[b]![word] ?? 0) + 1;
    _after1Total[b] = (_after1Total[b] ?? 0) + 1;
    final two = '$a $b';
    (_after2[two] ??= {})[word] = (_after2[two]![word] ?? 0) + 1;
    _after2Total[two] = (_after2Total[two] ?? 0) + 1;
  }

  /// The chance of [word] after [a] and [b] (Witten-Bell smoothing): what followed the two words, the rest of the
  /// chance going to what followed [b] alone, and the rest of that to how often the word came at all, each in the
  /// measure of how many different words followed. [smooth] gives a word never read a small chance, as the loss needs;
  /// [backoff] scales the chance passed down, so a model writing keeps closer to what it read.
  double chance(String a, String b, String word, {bool smooth = false, double backoff = 1}) {
    final once = _once[word] ?? 0;
    final alone = smooth ? (once + _k) / (_total + _k * _vocabulary) : (_total == 0 ? 0.0 : once / _total);
    final one = _blend(_after1[b], _after1Total[b], word, alone, backoff);
    return _blend(_after2['$a $b'], _after2Total['$a $b'], word, one, backoff);
  }

  static double _blend(Map<String, int>? next, int? total, String word, double lower, double backoff) {
    if (next == null || total == null) return lower;
    final kinds = next.length * backoff;
    return ((next[word] ?? 0) + kinds * lower) / (total + kinds);
  }

  /// The mean surprise on the sentences it never reads, in nats.
  double loss() {
    var surprise = 0.0;
    var count = 0;
    for (final sentence in PocketCorpus.heldOut(language)) {
      var a = _start;
      var b = _start;
      for (final word in [...sentence.split(' '), end]) {
        surprise -= math.log(chance(a, b, word, smooth: true));
        count++;
        a = b;
        b = word;
      }
    }
    return surprise / count;
  }

  /// The word it read most: what an overfit model repeats.
  String? get favourite {
    String? best;
    var most = 0;
    for (final MapEntry(:key, :value) in _once.entries) {
      if (key != end && value > most) {
        best = key;
        most = value;
      }
    }
    return best;
  }

  /// Writes a sentence at [temperature]. Before it has read anything it strings letters, as a model with random
  /// weights writes noise.
  Babble write({required double temperature, required math.Random random}) {
    if (known == 0) return (tokens: noise(language, random), hallucinating: false);
    final words = [..._once.keys];
    final said = <String>[];
    var hallucinating = false;
    var a = _start;
    var b = _start;
    while (said.length < longest) {
      final options = [
        for (final word in words)
          if (!(word == end && said.isEmpty)) word,
      ];
      final chances = [for (final word in options) chance(a, b, word, backoff: _writingBackoff)];
      final word = options[_pick(chances, temperature, random)];
      if (word == end) break;
      // A pair it never read is a join it made up.
      if ((_after1[b]?[word] ?? 0) == 0) hallucinating = true;
      said.add(word);
      a = b;
      b = word;
    }
    return (tokens: said, hallucinating: hallucinating);
  }

  static int _pick(List<double> chances, double temperature, math.Random random) {
    if (temperature < cold) {
      var best = 0;
      for (var i = 1; i < chances.length; i++) {
        if (chances[i] > chances[best]) best = i;
      }
      return best;
    }
    final shaped = [for (final p in chances) p <= 0 ? 0.0 : math.pow(p, 1 / temperature).toDouble()];
    final sum = shaped.fold(0.0, (a, b) => a + b);
    if (sum <= 0) return random.nextInt(chances.length);
    var at = random.nextDouble() * sum;
    for (var i = 0; i < shaped.length; i++) {
      at -= shaped[i];
      if (at <= 0) return i;
    }
    return shaped.length - 1;
  }

  /// The training curve from the first token to [tokens]: the loss at [points] even steps, starting at none read.
  static List<LossPoint> curve(String language, int tokens, {int points = 32}) {
    final model = TinyLm(language);
    if (tokens <= 0) return [(tokens: 0, loss: model.loss())];
    return [
      for (var i = 0; i < points; i++)
        () {
          model.trainTo((tokens * i / (points - 1)).round());
          return (tokens: model.trained, loss: model.loss());
        }(),
    ];
  }
}
