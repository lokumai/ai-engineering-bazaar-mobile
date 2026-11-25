/// Single source of truth for "what counts as sensitive" when data leaves
/// the app: to a crash report ([sentryBeforeSend] for the event,
/// [sentryBeforeBreadcrumb] for each breadcrumb) or to the console through
/// [AppLogger]. AppLogger masks the credential keys of a Map or a List
/// argument with [scrubBodyKeys], and runs every line it prints through
/// [maskSecrets] and [maskEmails].
///
/// Keeping one copy of the redaction policy is a security invariant, not
/// just DRY: two divergent copies guarantee that one exit eventually
/// leaks a secret the other would have stripped.
///
/// Pure and side-effect free — every function returns a new value and
/// never mutates its input, so it is trivially testable without booting
/// the SDK or a Dio client.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;

/// Header names whose values no log or view may show (compared
/// lower-cased). [scrubHeaders] drops them.
const Set<String> sensitiveHeaderNames = {'authorization', 'cookie', 'set-cookie'};

/// Parts of a header name that name a credential the body keys do not, such
/// as `Proxy-Authorization` and the api-key headers (`X-Api-Key`, `Api-Key`,
/// `x_api_key`). The crash-report scrubbers mask the whole value of a header
/// whose lower-cased name contains one.
const Set<String> sensitiveHeaderNameSubstrings = {'authorization', 'api-key', 'api_key', 'apikey'};

/// Body keys whose values are masked when any of these appears as a
/// lower-cased substring (so `accessToken`, `refreshToken`, `newPassword`
/// and `clientSecret` all match).
const Set<String> sensitiveBodyKeySubstrings = {'password', 'otp', 'token', 'refreshtoken', 'secret'};

/// Keys of the OpenID Connect protocol whose values are masked too: the
/// authorization code, the PKCE verifier, `state`, `nonce`, `session_state`
/// and `id_token_hint`. Compared whole and lower-cased, so `statusCode`,
/// `countryCode`, `errorCode` and `stateName` keep their values.
const Set<String> sensitiveExactKeys = {'code', 'code_verifier', 'state', 'nonce', 'session_state', 'id_token_hint'};

/// Replacement printed in place of a password, an OTP or another secret. A
/// class that holds one prints this in its `toString` instead of the value,
/// as `test/architecture/credential_to_string_test.dart` requires.
const String secretMask = '[REDACTED]';

/// Replacement emitted in place of a matched JWT.
const String jwtMask = '[REDACTED_JWT]';

/// JWT shape: 3 base64url segments separated by dots, each at least 4
/// chars. Conservative — does not match every theoretical JWT, but
/// matches every JWT this app actually mints.
///
/// A match starts only where a base64url run starts: tried inside a run, as at every `eyJ` of `eyJeyJ...`, the pattern
/// took about 4 s on 30,000 characters (review 9, finding 14), and now takes milliseconds. A token glued to a letter,
/// digit, `_` or `-` before it is not masked; a token in a header, a query or JSON follows a space, `=`, `:` or a quote.
/// `NativeScrubPatterns.kt` holds the same pattern.
final RegExp jwtPattern = RegExp(r'(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}');

/// Replace every JWT-shaped token inside [input] with [jwtMask].
String maskJwts(String input) => input.replaceAll(jwtPattern, jwtMask);

/// Whitespace in a separator: the characters Dart's `\s` matches and U+0085,
/// which ICU's `\s` adds, so a character that either engine reads as
/// whitespace separates on Dart and on Android alike. OpenJDK, the JVM of the
/// Android unit tests, reads `\s` as ASCII only, so no pattern uses `\s`.
const String _separatorSpace = r'[\t\n\u000b\f\r \u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]';

/// The characters Dart's `\s` matches, as the part of a class of the
/// characters a value may not hold. A value ends at one of them on every
/// engine and runs on over U+0085 as it did in Dart, so no engine masks a
/// value shorter than Dart did.
const String _valueSpace = r'\t\n\u000b\f\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff';

/// A JSON member whose value is a string or a number: its name, the colon
/// with the spaces around it, and its value.
///
/// This pattern, [namedValuePattern] and [bearerPattern] are public only so
/// that `test/architecture/sentry_native_scrub_patterns_test.dart` can
/// compare them with the copies the Android host scrubs native Sentry events
/// with. They spell out the classes instead of `\w`, `\d`, `\b`, `\s` and
/// `.`, which ICU, the regex engine of Android, and OpenJDK read differently
/// from Dart, and they take no case-insensitive flag, which Kotlin turns into
/// Unicode case folding.
@visibleForTesting
final RegExp jsonMemberPattern = RegExp(
  '${r'"([^"\\]{1,64})"('}$_separatorSpace*:$_separatorSpace'
  r'*)("(?:[^"\\]|\\[^\n\r\u2028\u2029])*"|-?[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)',
);

/// A `name=value` pair, as in a query string or a form body. A value that
/// starts with `[` is already a mask.
@visibleForTesting
final RegExp namedValuePattern = RegExp(
  r'(?<![A-Za-z0-9_.\-])([A-Za-z_][A-Za-z0-9_.\-]{0,63})=([^\[&'
  '$_valueSpace'
  r'''#"',;)}\]][^&'''
  '$_valueSpace'
  r'''#"',;)}\]]*)''',
);

/// The credentials of a Bearer authorization, the word in any case. A mask
/// starts with `[`, so it is not matched again.
@visibleForTesting
final RegExp bearerPattern = RegExp(
  '${r'(?<![A-Za-z0-9_])([Bb][Ee][Aa][Rr][Ee][Rr])'}$_separatorSpace${r'+[A-Za-z0-9\-._~+/]+=*'}',
);

/// Masks the secrets that [input] holds in a shape that names them: the
/// value of a JSON member or of a `name=value` pair whose name contains one
/// of [sensitiveBodyKeySubstrings] or is one of [sensitiveExactKeys], the
/// credentials of a `Bearer` authorization, and every JWT. A value that is
/// already a mask is kept.
///
/// [AppLogger] runs every line it prints through this, and the Sentry
/// scrubbers every text they send. A secret in free text has no shape to
/// find, so it has to be kept out of the text where it is written.
String maskSecrets(String input) {
  var text = input.contains('eyJ') ? maskJwts(input) : input;
  final lower = text.toLowerCase();
  if (lower.contains('bearer')) text = text.replaceAllMapped(bearerPattern, (match) => '${match[1]} $secretMask');
  if (!sensitiveBodyKeySubstrings.any(lower.contains) && !sensitiveExactKeys.any(lower.contains)) return text;
  if (text.contains('"')) {
    text = text.replaceAllMapped(jsonMemberPattern, (match) {
      final value = match[3]!;
      if (!_isSensitiveKey(match[1]) || value.startsWith('"[REDACTED')) return match[0]!;
      return '"${match[1]}"${match[2]}${value.startsWith('"') ? '"$secretMask"' : secretMask}';
    });
  }
  if (text.contains('=')) {
    text = text.replaceAllMapped(namedValuePattern, (m) => _isSensitiveKey(m[1]) ? '${m[1]}=$secretMask' : m[0]!);
  }
  return text;
}

/// Replacement emitted in place of a matched email address.
const String emailMask = '[REDACTED_EMAIL]';

/// Email shape, with the `@` either raw or percent-encoded as `%40`, the
/// way a URL query string carries it. The local part also accepts `%`, so
/// an encoded character such as the `%2B` in `jane%2Btag%40example.com`
/// is masked along with the rest of the address. Practical rather than
/// RFC 5322 complete: it matches the addresses people actually use.
///
/// The local part matches at most 64 characters, the RFC 5321 limit, so a
/// longer one keeps its leading characters. The bound keeps the scan linear:
/// unbounded, a long run of local-part characters without an `@` made it
/// quadratic, and past Dart's backtracking limit the match failed and the
/// address after the run was left unmasked.
///
/// Its letters are the Latin ones with their accented and extended forms, Greek, Cyrillic and Arabic, so an address
/// with a Turkish or other local part or domain is masked whole (review 11, native 2). They are spelled as ranges, not
/// `\p{L}`, which needs Dart's unicode flag the Kotlin copy cannot share.
final RegExp emailPattern = RegExp(
  r'[A-Za-z0-9À-ɏͰ-ϿЀ-ӿ؀-ۿ._%+-]{1,64}(?:@|%40)[A-Za-z0-9À-ɏͰ-ϿЀ-ӿ؀-ۿ-]+(?:\.[A-Za-z0-9À-ɏͰ-ϿЀ-ӿ؀-ۿ-]+)*\.[A-Za-zÀ-ɏͰ-ϿЀ-ӿ؀-ۿ]{2,}',
);

/// Replace every email address inside [input] with [emailMask].
///
/// A string without an `@` or a `%40` holds no address, so it is returned
/// without a scan: AppLogger runs every printed line through this.
String maskEmails(String input) {
  if (!input.contains('@') && !input.contains('%40')) return input;
  return input.replaceAll(emailPattern, emailMask);
}

/// Return a copy of [headers] with [sensitiveHeaderNames] removed.
/// Generic over value type so both `Map<String, String>` (Sentry) and
/// `Map<String, dynamic>` (Dio request options) work.
Map<K, V> scrubHeaders<K, V>(Map<K, V> headers) {
  return Map<K, V>.fromEntries(
    headers.entries.where((e) => !sensitiveHeaderNames.contains(e.key.toString().toLowerCase())),
  );
}

/// Return a copy of [body] in which the value of every key that contains
/// one of [sensitiveBodyKeySubstrings], or is one of [sensitiveExactKeys],
/// is replaced by [secretMask], in nested maps and lists too. The key
/// stays, so a reader still sees that the field was there, and a null value
/// stays null.
///
/// A body that is not a Map or a List (raw String, multipart) passes
/// through untouched, since it would require shape-specific scrubbing;
/// callers that also handle raw string bodies should additionally run
/// [maskJwts] over the serialized form to catch embedded tokens.
Object? scrubBodyKeys(Object? body) => _scrubKeys(body, _isSensitiveKey);

bool _isSensitiveKey(Object? key) {
  final lower = '$key'.toLowerCase();
  return sensitiveBodyKeySubstrings.any(lower.contains) || sensitiveExactKeys.contains(lower);
}

Object? _scrubKeys(Object? body, bool Function(Object? key) isSecret) => switch (body) {
  Map() => <String, dynamic>{
    for (final MapEntry(:key, :value) in body.entries)
      '$key': isSecret(key) && value != null ? secretMask : _scrubKeys(value, isSecret),
  },
  List() => [for (final item in body) _scrubKeys(item, isSecret)],
  _ => body,
};
