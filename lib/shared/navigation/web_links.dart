/// The site's address for shared widgets and features (Decision A37): shared code may not import `AppConfig`, which
/// is infrastructure, so `AppScope` provides this from `AppConfig.contentBaseUrl`.
final class WebLinks {
  /// [contentBaseUrl] ends in `/`.
  const WebLinks(this.contentBaseUrl);

  final String contentBaseUrl;

  /// The web page at [webPath]: the base URL and the path concatenated (spec 3.4.7), never `Uri.resolve`, so a base
  /// URL with a path keeps it.
  Uri webPage(String webPath) => Uri.parse('$contentBaseUrl$webPath');

  /// The site's home page.
  Uri get site => Uri.parse(contentBaseUrl);

  /// The site's privacy note, which covers the app too (web D138): the address the stores are given.
  Uri get privacy => webPage('legend/#privacy');
}
