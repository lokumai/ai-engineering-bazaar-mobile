/// Returns [value], the `contentBaseUrl` the app starts with, or throws a [StateError] that names the define and the
/// rule: it must be set, start with `https://` (A32, no cleartext) and end with a slash (site paths are appended).
String requireContentBaseUrl(String value) {
  if (value.isEmpty) {
    throw StateError(
      'CONTENT_BASE_URL is not set. Run with --dart-define=CONTENT_BASE_URL=https://ai-bazaar.lokum.dev/ '
      'or another https address ending in a slash.',
    );
  }
  if (!value.startsWith('https://') || !value.endsWith('/')) {
    throw StateError(
      'CONTENT_BASE_URL must be an https address ending in a slash, such as https://ai-bazaar.lokum.dev/',
    );
  }
  return value;
}
