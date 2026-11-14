import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every message in intl_en.arb follows the web's copy register (Decision A12). The bans, the retired words and the
/// exemptions are copied from the web repo at 29c511c, `tests/unit/copy-register.test.ts`; names and patterns are
/// verbatim, reasons are shortened to one line.
void main() {
  final arb = jsonDecode(File('lib/l10n/intl_en.arb').readAsStringSync()) as Map<String, dynamic>;
  final messages = {
    for (final MapEntry(:key, :value) in arb.entries)
      if (!key.startsWith('@')) key: value as String,
  };

  test('reads every message of intl_en.arb', () {
    expect(messages.keys, contains('app_title'));
  });

  test('fires on every ban', () {
    const samples = {
      'exclamation mark': 'Saved!',
      'anthropomorphism (first person)': 'We saved your progress',
      'condescension': 'Simply restore the file',
      'apology or supplication': 'Sorry, that failed',
      'valid / invalid': 'Invalid file',
      'praise': 'Well done',
      'you forgot': 'You forgot the file',
      'PLANNED': 'Not yet written',
    };
    for (final MapEntry(key: ban, value: text) in samples.entries) {
      expect(_offences(text), contains(startsWith('$ban:')), reason: text);
    }
  });

  test('fires on every retired word, a one-word label included', () {
    const old =
        'SHEET 07 of the drawing set · SUBSYSTEM 02 · NOT DRAWN · the index sheet · signed off by the drafter · '
        'title block · the register · EXTENT · UPTIME';
    expect(_retired.where((rule) => rule.pattern.hasMatch(old)), hasLength(_retired.length));
    expect(_offences('Sheets'), isNotEmpty);
  });

  test('exempts the reader-owned Keep my data and code names in backticks', () {
    expect(_offences('Keep my data'), isEmpty);
    expect(_offences('Pass `sheet` to the parser'), isEmpty);
    expect(_offences('Could not open {url}'), isEmpty);
  });

  test('reads the branch text of a plural message', () {
    expect(_offences('{count, plural, one{# sheet} other{# sheets}}'), isNotEmpty);
    expect(_offences('{count, plural, one{# module} other{# modules}}'), isEmpty);
  });

  test('no message in intl_en.arb breaks the copy register', () {
    final offences = [
      for (final MapEntry(:key, :value) in messages.entries)
        if (!_ownerWords.containsKey(key))
          for (final offence in _offences(value)) '$key: $offence',
    ];
    expect(offences, isEmpty, reason: 'say it the web way (tests/unit/copy-register.test.ts in the web repo)');
  });
}

/// Messages the owner chose in words the register bans, each with the decision: they are not scanned. Keep it short.
const _ownerWords = {
  // Welcome's button to the story of the Bazaar (plan 1BD).
  'welcome_to_story': 'Our story: the owner, 2026-11-15',
};

/// `BANS`, `copy-register.test.ts:181-238`. Every pattern but the exclamation mark is case-insensitive, as on the web.
final _bans = <({String name, RegExp pattern, String why})>[
  (name: 'exclamation mark', pattern: RegExp(r'!'), why: 'Most things are not that exciting.'),
  (
    name: 'anthropomorphism (first person)',
    pattern: RegExp(r"\b(?:I|I'm|I've|we|we'll|we've|my|our)\b", caseSensitive: false),
    why: 'The software does not speak as a person.',
  ),
  (
    name: 'condescension',
    pattern: RegExp(r'\b(?:easy|easily|just|simply|simple|quick|quickly)\b', caseSensitive: false),
    why: 'It tells a struggling reader the thing is trivial.',
  ),
  (
    name: 'apology or supplication',
    pattern: RegExp(r'\b(?:please|sorry|oops|whoops)\b', caseSensitive: false),
    why: 'GOV.UK bans them from service copy.',
  ),
  (
    name: 'valid / invalid',
    pattern: RegExp(r'\b(?:invalid|valid)\b', caseSensitive: false),
    why: 'An error says what to do instead.',
  ),
  (
    name: 'praise',
    pattern: RegExp(
      r'\b(?:great|awesome|nice work|well done|congratulations|congrats|excellent|perfect|amazing)\b',
      caseSensitive: false,
    ),
    why: 'The reward for finishing is that the system logged it accurately.',
  ),
  (
    name: 'you forgot',
    pattern: RegExp(r'\byou forgot\b', caseSensitive: false),
    why: 'An error message never blames the reader.',
  ),
  (
    name: 'PLANNED',
    pattern: RegExp(r'\bnot\s+(?:yet\s+)?(?:drawn|written)\b', caseSensitive: false),
    why: 'The register has one word for this state, Planned.',
  ),
];

/// `RETIRED`, `copy-register.test.ts:401-416`, each with the word to say instead; reported as `retired vocabulary`.
final _retired = <({RegExp pattern, String instead})>[
  (pattern: RegExp(r'\bdrawing set\b', caseSensitive: false), instead: 'the curriculum'),
  (pattern: RegExp(r'\bindex sheet\b', caseSensitive: false), instead: 'the catalog'),
  (pattern: RegExp(r'\bsheets?\b', caseSensitive: false), instead: 'module'),
  (pattern: RegExp(r'\bsubsystems?\b', caseSensitive: false), instead: 'level'),
  (pattern: RegExp(r'\bsign(?:s|ed|ing)?[ -]offs?\b', caseSensitive: false), instead: 'complete / completed'),
  (pattern: RegExp(r'\bnot (?:yet )?drawn\b', caseSensitive: false), instead: 'planned'),
  (pattern: RegExp(r'\btitle block\b', caseSensitive: false), instead: 'module info'),
  (pattern: RegExp(r'\bthe register\b', caseSensitive: false), instead: 'your progress'),
  (pattern: RegExp(r'\bdrafters?\b', caseSensitive: false), instead: 'you, or the account'),
  (pattern: RegExp(r'\bextent\b', caseSensitive: false), instead: 'length'),
  (pattern: RegExp(r'\buptime\b', caseSensitive: false), instead: 'streak'),
];

/// `ALLOWED`, `copy-register.test.ts:244-287`: the text it matches, the ban it exempts (`*` for every ban) and why.
final _allowed = <({RegExp text, String ban, String why})>[
  (
    text: RegExp(r'quick check', caseSensitive: false),
    ban: 'condescension',
    why: 'The authored name of a section in the corpus.',
  ),
  (
    text: RegExp(r'^Keep my data$'),
    ban: 'anthropomorphism (first person)',
    why: 'The exact model decline label; the possessive is the reader\'s.',
  ),
  (
    text: RegExp(r'^(?:https?:|\/|#|data-|aria-|role$)'),
    ban: '*',
    why: 'A URL, a route, a selector or an attribute name is not prose.',
  ),
  (text: RegExp(r'SHA-256|Intl\.|navigator\.|crypto\.|localStorage'), ban: '*', why: 'An API name.'),
  (
    text: RegExp(r'^Planned to cover .* the module is not written yet$'),
    ban: 'PLANNED',
    why: 'A sentence about the state, not a label for it.',
  ),
  (text: RegExp(r'(?:^|\s)hl-'), ban: 'retired vocabulary', why: 'A stylesheet class list.'),
];

bool _exempt(String text, String ban) =>
    _allowed.any((entry) => (entry.ban == '*' || entry.ban == ban) && entry.text.hasMatch(text));

/// The ICU syntax of a message, in the order it is replaced by a space: a simple placeholder, a plural or select
/// header, a branch selector, then every remaining `}` and `#`. The text of every branch stays, since a reader sees it.
final _icuSyntax = [
  RegExp(r'\{\s*\w+\s*\}'),
  RegExp(r'\{\s*\w+\s*,\s*(?:plural|select|selectordinal)\s*,'),
  RegExp(r'(?:=\d+|\w+)\s*\{'),
  RegExp(r'[}#]'),
];

/// The web's prose filter (`looksLikeProse`) is not applied: every ARB value is reader-visible copy, and a one-word
/// label such as `Sheets` or `Done!` must not slip through it.
List<String> _offences(String text) {
  final visible = _icuSyntax.fold(text, (current, syntax) => current.replaceAll(syntax, ' '));
  final prose = visible.replaceAll(RegExp(r'`[^`]*`'), '');
  return [
    for (final ban in _bans)
      if (ban.pattern.hasMatch(visible) && !_exempt(visible, ban.name)) '${ban.name}: $text',
    for (final rule in _retired)
      if (rule.pattern.hasMatch(prose) && !_exempt(visible, 'retired vocabulary'))
        'retired vocabulary: $text (say ${rule.instead})',
  ];
}
