import 'dart:math' as math;

/// The rules by which typed words find words in the course text (web M59, D95; `src/lib/search/normalise.ts` and
/// `searchOptions`), shared by the catalog's search, which finds them, and the reader, which marks them (plan 7.1).

const _turkishFold = {'ı': 'i', 'ğ': 'g', 'ş': 's', 'ç': 'c', 'ö': 'o', 'ü': 'u', 'â': 'a', 'î': 'i', 'û': 'u'};
const _persianLetters = {'ي': 'ی', 'ى': 'ی', 'ك': 'ک', 'ة': 'ه', 'آ': 'ا', 'أ': 'ا', 'إ': 'ا'};
final _persianDrop = RegExp('[\u200c\u0640\u064b-\u0652\u0670]');
final _persianDigit = RegExp('[۰-۹٠-٩]');

/// One word as both sides compare it (web `normalise`): English lower-cased; Turkish lower-cased by the Turkish rules
/// and folded to plain letters, so "gorev" finds "görev"; Persian with the Arabic forms made Persian, the non-joiner and
/// the vowel marks dropped and the digits made ASCII.
String normalise(String term, String lang) {
  switch (lang) {
    case 'tr':
      final lower = term.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
      return lower.replaceAllMapped(RegExp('[ığşçöüâîû]'), (m) => _turkishFold[m[0]]!);
    case 'fa':
      return term
          .replaceAllMapped(RegExp('[يىكةآأإ]'), (m) => _persianLetters[m[0]]!)
          .replaceAll(_persianDrop, '')
          .replaceAllMapped(_persianDigit, (m) {
            final unit = m[0]!.codeUnitAt(0);
            return '${unit - (unit >= 0x06f0 ? 0x06f0 : 0x0660)}';
          })
          .toLowerCase();
    default:
      return term.toLowerCase();
  }
}

final _spaceOrPunctuation = RegExp(r'[\n\r\p{Z}\p{P}\s]+', unicode: true);
final _scriptSeam = RegExp('(?<=[A-Za-z0-9])\u200c?(?=[\u0600-\u06ff])|(?<=[\u0600-\u06ff])\u200c?(?=[A-Za-z0-9])');

/// The words of a text (web `tokenize`): split on space and punctuation and where a Latin word meets a Persian one; a
/// word joined by a non-joiner is kept as each part and whole.
List<String> tokenize(String text) => [
  for (final word in text.replaceAll(_scriptSeam, ' ').split(_spaceOrPunctuation))
    if (word.isNotEmpty)
      ...(word.contains('\u200c') ? [...word.split('\u200c').where((p) => p.isNotEmpty), word] : [word]),
];

/// The words of a query (web `queryTokenize`): a word typed with a non-joiner is searched whole.
List<String> queryTokenize(String text) => [
  for (final word in text.replaceAll(_scriptSeam, ' ').split(_spaceOrPunctuation))
    if (word.isNotEmpty) word,
];

/// The terms of [query] as the text is matched: its words normalised in [lang], each of two letters or more.
List<String> searchTerms(String query, String lang) => [
  for (final word in queryTokenize(query))
    if (normalise(word, lang) case final term when term.length >= 2) term,
];

/// The words of a text as drawn, with where each stands: letters and digits between space and punctuation.
final wordPattern = RegExp(r'[^\s\p{P}]+', unicode: true);

/// Whether the word [word] as written answers one of [terms] in [lang].
bool matchesTerms(String word, List<String> terms, String lang) {
  final normal = normalise(word, lang);
  return terms.any((term) => termQuality(term, normal) > 0);
}

/// How well the indexed word [word] answers the typed [term]: 1 for the word itself, less for a word it starts or one
/// a letter or so off; 0 for none.
double termQuality(String term, String word) {
  if (word == term) return 1;
  if (term.length >= 3 && word.startsWith(term)) return 0.5 * term.length / word.length + 0.25;
  final edits = (term.length * 0.15).round();
  if (edits > 0 && (word.length - term.length).abs() <= edits && _within(term, word, edits)) return 0.4;
  return 0;
}

/// Whether [a] and [b] are at most [max] edits apart (Levenshtein, stopped early).
bool _within(String a, String b, int max) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    var best = current[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = math.min(math.min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
      best = math.min(best, current[j]);
    }
    if (best > max) return false;
    previous = current;
  }
  return previous[b.length] <= max;
}
