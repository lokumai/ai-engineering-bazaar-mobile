import 'package:ai_engineering_bazaar/shared/content/domain/content_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'joins the base and a site path',
    () => expect(
      joinContentUrl('https://ai-bazaar.lokum.dev/', 'api/v1/index.json'),
      'https://ai-bazaar.lokum.dev/api/v1/index.json',
    ),
  );

  test(
    'keeps a sub-path of the base',
    () => expect(
      joinContentUrl('https://example.org/bazaar/', 'api/v1/diagrams/x.svg', version: 'ab'),
      'https://example.org/bazaar/api/v1/diagrams/x.svg?v=ab',
    ),
  );

  test(
    'refuses a base without a trailing slash',
    () => expect(() => joinContentUrl('https://example.org/bazaar', 'a.json'), throwsArgumentError),
  );

  test(
    'refuses a site path with a leading slash',
    () => expect(() => joinContentUrl('https://example.org/', '/a.json'), throwsArgumentError),
  );
}
