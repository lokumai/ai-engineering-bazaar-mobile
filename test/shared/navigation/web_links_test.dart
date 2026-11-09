import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const links = WebLinks('https://ai-bazaar.lokum.dev/');

  test('site is the content base URL', () {
    expect(links.site, Uri.parse('https://ai-bazaar.lokum.dev/'));
  });

  test('a web page is the base URL and the web path concatenated (spec 0.5)', () {
    expect(links.webPage('courses/alpha/first/'), Uri.parse('https://ai-bazaar.lokum.dev/courses/alpha/first/'));
    expect(
      links.webPage('everyone/courses/alpha/first/'),
      Uri.parse('https://ai-bazaar.lokum.dev/everyone/courses/alpha/first/'),
    );
  });
}
