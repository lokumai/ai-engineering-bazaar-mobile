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
/// It can also read the course's modules the reader finished ([read]), holding out a tenth of each to measure its loss
/// on, so a module it reads makes its loss fall as its own text does.
///
/// Its state follows from the number of tokens of its text it read and the modules it read, so a kept count and the
/// modules' keys rebuild it.
final class TinyLm {
  TinyLm(this.language)
    : _stream = [
        for (final sentence in PocketCorpus.training(language)) ...[...sentence.split(' '), end],
      ] {
    _words.addAll({..._stream, for (final sentence in PocketCorpus.heldOut(language)) ...sentence.split(' ')});
  }

  /// A model that has read [tokens] tokens.
  factory TinyLm.trained(String language, int tokens) => TinyLm(language)..trainTo(tokens);

  final String language;
  final List<String> _stream;

  /// Every word its loss gives a chance to: its text's, the held-out sentences', and those of the modules it read.
  final Set<String> _words = {};

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

  /// What it counted of everything it read.
  final _Counts _all = _Counts();

  /// What it counted of each module it read, by the module's key: a topic it can keep to while it writes.
  final Map<String, _Counts> _topics = {};

  int _trained = 0;
  String _a = _start;
  String _b = _start;

  /// The tokens of its own text read so far.
  int get trained => _trained;

  /// The tokens of the course's modules it read ([read]).
  int get readTokens => _read;
  int _read = 0;

  /// Every token it read, of its text and of the modules.
  int get total => _trained + _read;

  /// Reads a module's [sentences] (`module_sentences.dart`), each ending in [end], all but every tenth, which it holds
  /// out to measure its loss on, as a training run keeps a test set from each source; returns the tokens read.
  /// [holdOut] false reads them without holding the tenth out again, for a curve that held them out first.
  /// With a [topic] (the module's key), it also counts the module apart, as a topic to keep to ([write]).
  int read(List<List<String>> sentences, {bool holdOut = true, String? topic}) {
    final (taught, tested) = splitOut(sentences);
    if (holdOut) _tested.addAll(tested);
    for (final sentence in [...taught, ...tested]) {
      for (final word in sentence) {
        _words.add(word);
      }
    }
    var count = 0;
    final own = topic == null ? null : (_topics[topic] ??= _Counts());
    for (final sentence in taught) {
      var a = _start;
      var b = _start;
      for (final word in [...sentence, end]) {
        _all.add(a, b, word);
        own?.add(a, b, word);
        a = b;
        b = word;
        count++;
      }
    }
    _read += count;
    return count;
  }

  /// The words it has read at least once.
  int get known => _all.once.length - (_all.once.containsKey(end) ? 1 : 0);

  /// The modules it read and can keep to as topics, by key, in the order it read them.
  List<String> get topics => [..._topics.keys];

  /// The sentences of the modules it read that it holds out, to measure its loss on with its own held-out ones.
  final List<List<String>> _tested = [];

  /// [sentences] parted into those a model reads and every tenth, which it holds out.
  static (List<List<String>>, List<List<String>>) splitOut(List<List<String>> sentences) => (
    [
      for (final (i, sentence) in sentences.indexed)
        if (i % 10 != 9) sentence,
    ],
    [
      for (final (i, sentence) in sentences.indexed)
        if (i % 10 == 9) sentence,
    ],
  );

  /// Holds out the tenth of each of [modules] before reading any, so every point of a curve is measured on the same
  /// sentences.
  void holdOutAll(Iterable<List<List<String>>> modules) {
    for (final module in modules) {
      _tested.addAll(splitOut(module).$2);
      for (final sentence in module) {
        _words.addAll(sentence);
      }
    }
  }

  /// The tokens of one pass over its text.
  int get epoch => _stream.length;

  /// Reads the next [count] tokens, from the top again after the last, and returns the words read.
  List<String> train(int count) {
    final read = <String>[];
    for (var i = 0; i < count; i++) {
      final word = _stream[_trained % _stream.length];
      _all.add(_a, _b, word);
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

  /// The chance of [word] after [a] and [b] (Witten-Bell smoothing): what followed the two words, the rest of the
  /// chance going to what followed [b] alone, and the rest of that to how often the word came at all, each in the
  /// measure of how many different words followed. [smooth] gives a word never read a small chance, as the loss needs;
  /// [backoff] scales the chance passed down, so a model writing keeps closer to what it read.
  double chance(String a, String b, String word, {bool smooth = false, double backoff = 1}) {
    final once = _all.once[word] ?? 0;
    final total = _all.total;
    final alone = smooth ? (once + _k) / (total + _k * _words.length) : (total == 0 ? 0.0 : once / total);
    return _all.chance(a, b, word, alone, backoff);
  }

  /// The chance of [word] after [a] and [b] keeping to [topic]: half what followed them in the module, half what
  /// followed them in everything it read, so it writes of the module in the words of all it read.
  double _topicChance(_Counts? topic, String a, String b, String word, double backoff) {
    final all = chance(a, b, word, backoff: backoff);
    if (topic == null) return all;
    final total = _all.total;
    final alone = total == 0 ? 0.0 : (_all.once[word] ?? 0) / total;
    return _topicShare * topic.chance(a, b, word, alone, backoff) + (1 - _topicShare) * all;
  }

  /// How much of a word's chance a topic decides.
  static const _topicShare = 0.5;

  /// The mean surprise on the sentences it never reads, in nats.
  double loss() {
    var surprise = 0.0;
    var count = 0;
    for (final sentence in [for (final s in PocketCorpus.heldOut(language)) s.split(' '), ..._tested]) {
      var a = _start;
      var b = _start;
      for (final word in [...sentence, end]) {
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
    for (final MapEntry(:key, :value) in _all.once.entries) {
      if (key != end && value > most) {
        best = key;
        most = value;
      }
    }
    return best;
  }

  /// Writes a sentence at [temperature]. Before it has read anything it strings letters, as a model with random
  /// weights writes noise.
  ///
  /// Words of its [recent] answers are less likely (a repetition penalty, as large models have), all but its commonest
  /// words, which a sentence needs; and an answer the same as a recent one is written again, up to three times. Cold,
  /// it takes its likeliest words regardless, every time.
  ///
  /// With a [topic], a module it read, it keeps to the module: half of each word's chance is what followed in the
  /// module. With [thoughts] above one it writes that many sentences and says the one it judges best ([judge]): the
  /// one that reads most smoothly to it and keeps most to the topic; hot, it judges loosely, cold, it says the best.
  Babble write({
    required double temperature,
    required math.Random random,
    List<List<String>> recent = const [],
    String? topic,
    int thoughts = 1,
  }) {
    if (known == 0) return (tokens: noise(language, random), hallucinating: false);
    final penalise = temperature >= cold && recent.isNotEmpty;
    final common = penalise ? _commonest(_common) : const <String>{};
    final avoid = penalise ? {for (final said in recent) ...said}.difference(common) : const <String>{};
    final keep = topic == null ? null : _topics[topic];
    final drafts = <Babble>[];
    for (var i = 0; i < math.max(1, thoughts); i++) {
      var written = _write(temperature, random, avoid, keep);
      for (var tries = 0; penalise && tries < 3 && recent.any((said) => _same(said, written.tokens)); tries++) {
        written = _write(temperature, random, avoid, keep);
      }
      drafts.add(written);
    }
    if (drafts.length == 1) return drafts.single;
    final fresh = [
      for (final draft in drafts)
        if (!recent.any((said) => _same(said, draft.tokens))) draft,
    ];
    final pool = fresh.isEmpty ? drafts : fresh;
    // A judgement is a log chance: raised back to a chance, the temperature picks among them as among words.
    final scores = [for (final draft in pool) math.exp(_judgeTemper * judge(draft.tokens, topic: topic))];
    return pool[_pick(scores, temperature, random)];
  }

  /// How sharply its judgement picks among its drafts.
  static const _judgeTemper = 2.0;

  /// How it judges a sentence it wrote: the mean log chance of its words and its end (how smoothly it reads, to what
  /// it read), and, with a [topic], a share for the words that mark the topic; a sentence of fewer than four words is
  /// judged a little lower.
  double judge(List<String> tokens, {String? topic}) {
    if (tokens.isEmpty) return double.negativeInfinity;
    final keep = topic == null ? null : _topics[topic];
    var sum = 0.0;
    var a = _start;
    var b = _start;
    for (final word in [...tokens, end]) {
      sum += math.log(math.max(1e-9, _topicChance(keep, a, b, word, 1)));
      a = b;
      b = word;
    }
    var score = sum / (tokens.length + 1);
    if (keep != null) {
      final marks = _keywords(keep);
      score += _topicWeight * tokens.where(marks.contains).length / tokens.length;
    }
    if (tokens.length < 4) score -= 0.5;
    return score;
  }

  /// How much a sentence's keeping to its topic counts beside how smoothly it reads.
  static const _topicWeight = 1.5;

  /// The words that mark [topic]: those it read in the module far more often than elsewhere, not short and not among
  /// its commonest.
  Set<String> _keywords(_Counts topic) {
    final kept = topic.keywords;
    if (kept != null) return kept;
    final common = _commonest(40);
    final ranked = [
      for (final MapEntry(:key, :value) in topic.once.entries)
        if (key != end && key.length > 3 && !common.contains(key))
          (key, value / (_all.once[key] ?? value) * math.log(1 + value)),
    ]..sort((x, y) => y.$2.compareTo(x.$2));
    return topic.keywords = {for (final (word, _) in ranked.take(40)) word};
  }

  /// How many sentences it writes to choose one from, by the modules it read: one before it read any, three more for
  /// each, up to twenty. The more of the course it read, the more it thinks before it speaks.
  static int thoughtsFor(int modules) => math.min(20, 1 + 3 * modules);

  Babble _write(double temperature, math.Random random, Set<String> avoid, _Counts? keep) {
    final said = <String>[];
    var hallucinating = false;
    var a = _start;
    var b = _start;
    while (said.length < longest) {
      // The words worth weighing: what followed the last words, here or in the topic, and its commonest words, through
      // which a hot model makes up a join; the rest are too unlikely to matter.
      final options = [
        for (final word in <String>{
          ...?_all.after2['$a $b']?.keys,
          ...?_all.after1[b]?.keys,
          ...?keep?.after1[b]?.keys,
          ..._head(),
        })
          if (!(word == end && said.isEmpty)) word,
      ];
      final chances = [
        for (final word in options)
          _topicChance(keep, a, b, word, _writingBackoff) / (avoid.contains(word) ? _penalty : 1),
      ];
      final word = options[_pick(chances, temperature, random)];
      if (word == end) break;
      // A pair it never read is a join it made up.
      if ((_all.after1[b]?[word] ?? 0) == 0) hallucinating = true;
      said.add(word);
      a = b;
      b = word;
    }
    return (tokens: said, hallucinating: hallucinating);
  }

  /// Its two hundred commonest words, counted again only when it has read on.
  Set<String> _head() {
    if (_headAt != _all.total) {
      _headAt = _all.total;
      _headWords = _commonest(200);
    }
    return _headWords;
  }

  int _headAt = -1;
  Set<String> _headWords = const {};

  /// How much less likely a word of a recent answer is.
  static const _penalty = 2.5;

  /// How many of its commonest words are never penalised.
  static const _common = 12;

  Set<String> _commonest(int count) {
    final ranked = _all.once.entries.where((entry) => entry.key != end).toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    return {for (final entry in ranked.take(count)) entry.key};
  }

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  /// The training curve from the first token to [tokens] of its text, the loss at [points] even steps from none
  /// read, its x the tokens read in all. Each of [readings] (the tokens of its text read when it read a module, and the
  /// module's sentences) is read at its place, with a point just before it and one just after.
  static List<LossPoint> curve(
    String language,
    int tokens, {
    List<(int, List<List<String>>)> readings = const [],
    int points = 32,
  }) {
    final model = TinyLm(language)..holdOutAll(readings.map((reading) => reading.$2));
    final pending = [...readings]..sort((a, b) => a.$1.compareTo(b.$1));
    final drawn = <LossPoint>[(tokens: 0, loss: model.loss())];
    void mark() {
      final point = (tokens: model.total, loss: model.loss());
      if (drawn.last.tokens == point.tokens) drawn.removeLast();
      drawn.add(point);
    }

    if (tokens <= 0 && pending.isEmpty) return drawn;
    for (var i = 1; i < points; i++) {
      final to = (tokens * i / (points - 1)).round();
      while (pending.isNotEmpty && pending.first.$1 <= to) {
        final (at, sentences) = pending.removeAt(0);
        model.trainTo(at);
        mark();
        model.read(sentences, holdOut: false);
        mark();
      }
      model.trainTo(to);
      mark();
    }
    return drawn;
  }
}

/// What a model counted of some text: how often each word came, and which word followed one word and which two.
final class _Counts {
  final Map<String, int> once = {};
  final Map<String, Map<String, int>> after1 = {};
  final Map<String, Map<String, int>> after2 = {};
  final Map<String, int> after1Total = {};
  final Map<String, int> after2Total = {};
  int total = 0;

  /// The words that mark this text as a topic, once counted; counted again after it reads on.
  Set<String>? keywords;

  void add(String a, String b, String word) {
    once[word] = (once[word] ?? 0) + 1;
    total++;
    (after1[b] ??= {})[word] = (after1[b]![word] ?? 0) + 1;
    after1Total[b] = (after1Total[b] ?? 0) + 1;
    final two = '$a $b';
    (after2[two] ??= {})[word] = (after2[two]![word] ?? 0) + 1;
    after2Total[two] = (after2Total[two] ?? 0) + 1;
    keywords = null;
  }

  /// The chance of [word] after [a] and [b] (Witten-Bell smoothing): what followed the two words, the rest of the
  /// chance going to what followed [b] alone, and the rest of that to [alone], each in the measure of how many
  /// different words followed; [backoff] scales the chance passed down.
  double chance(String a, String b, String word, double alone, double backoff) {
    final one = _blend(after1[b], after1Total[b], word, alone, backoff);
    return _blend(after2['$a $b'], after2Total['$a $b'], word, one, backoff);
  }

  static double _blend(Map<String, int>? next, int? total, String word, double lower, double backoff) {
    if (next == null || total == null) return lower;
    final kinds = next.length * backoff;
    return ((next[word] ?? 0) + kinds * lower) / (total + kinds);
  }
}
