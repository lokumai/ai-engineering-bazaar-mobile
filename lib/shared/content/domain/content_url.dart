/// The URL of [sitePath] on the site at [contentBaseUrl] (spec 3.4.7), with `?v=<version>` when [version] is given.
///
/// The base and the path are concatenated, never resolved: `Uri.resolve('/x')` would drop a sub-path of the base.
/// Throws an [ArgumentError] unless [contentBaseUrl] ends with `/` and [sitePath] does not start with one.
String joinContentUrl(String contentBaseUrl, String sitePath, {String? version}) {
  if (!contentBaseUrl.endsWith('/')) {
    throw ArgumentError.value(contentBaseUrl, 'contentBaseUrl', 'must end with a slash');
  }
  if (sitePath.startsWith('/')) throw ArgumentError.value(sitePath, 'sitePath', 'must not start with a slash');
  final url = '$contentBaseUrl$sitePath';
  return version == null ? url : '$url?v=$version';
}
