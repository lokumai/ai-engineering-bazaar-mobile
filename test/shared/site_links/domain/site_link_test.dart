import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:flutter_test/flutter_test.dart';

final _site = Uri.parse('https://example.test/');

SiteLink? _parse(String link) => SiteLink.parse(Uri.parse(link), _site);

void main() {
  group('SiteLink.parse', () {
    test("reads the site's module, level and catalog pages in both tracks", () {
      expect(_parse('https://example.test/courses/alpha/first/'), const SiteModule(Track.engineers, 'alpha/first'));
      expect(
        _parse('https://example.test/everyone/courses/alpha/first/'),
        const SiteModule(Track.everyone, 'alpha/first'),
      );
      expect(_parse('https://example.test/sheets/alpha/'), const SiteLevel(Track.engineers, 'alpha'));
      expect(_parse('https://example.test/courses/alpha/'), const SiteLevel(Track.engineers, 'alpha'));
      expect(_parse('https://example.test/everyone/sheets/'), const SiteCatalog(Track.everyone));
      expect(_parse('https://example.test/sheets'), const SiteCatalog(Track.engineers));
    });

    test('reads past the language of a link; the app keeps its own', () {
      expect(_parse('https://example.test/tr/courses/alpha/first/'), const SiteModule(Track.engineers, 'alpha/first'));
      expect(
        _parse('https://example.test/fa/everyone/courses/alpha/first/'),
        const SiteModule(Track.everyone, 'alpha/first'),
      );
    });

    test('reads a transfer from the site and from the app scheme', () {
      expect(_parse('https://example.test/transfer/#t=abc_-1'), const SiteTransfer('abc_-1'));
      expect(_parse('aibazaar://transfer#t=abc'), const SiteTransfer('abc'));
      expect(_parse('aibazaar://transfer#other=1&t=abc'), const SiteTransfer('abc'));
    });

    test('leaves alone what is not one of its pages', () {
      for (final link in [
        'https://other.test/courses/alpha/first/',
        'http://example.test/courses/alpha/first/',
        'https://example.test/',
        'https://example.test/legend/',
        'https://example.test/courses/alpha/first/extra/',
        'https://example.test/transfer/',
        'https://example.test/everyone/transfer/#t=abc',
        'aibazaar://other#t=abc',
        // escapes that are not UTF-8, as a link cut short
        'aibazaar://transfer#t=%ff',
        'aibazaar://transfer#t=%E0%A4%A',
        'https://example.test/transfer/#t=%E0%A4',
        // in the path too, as an old Latin-1 address (review 5, finding 1)
        'https://example.test/courses/%FF/x',
        'https://example.test/%E9t%E9',
        'mailto:someone@example.test',
      ]) {
        expect(_parse(link), isNull, reason: link);
      }
    });
  });

  test('transferLink carries the payload in the fragment, which reads back', () {
    final link = transferLink(_site, 'abc_-1');
    expect(link.toString(), 'https://example.test/transfer/#t=abc_-1');
    expect(SiteLink.parse(link, _site), const SiteTransfer('abc_-1'));
  });
}
