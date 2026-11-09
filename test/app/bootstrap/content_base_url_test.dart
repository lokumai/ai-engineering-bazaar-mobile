import 'package:ai_engineering_bazaar/app/bootstrap/content_base_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'an empty value names the define',
    () => expect(
      () => requireContentBaseUrl(''),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('--dart-define=CONTENT_BASE_URL='))),
    ),
  );

  test(
    'an http address is refused (A32)',
    () => expect(() => requireContentBaseUrl('http://localhost:3111/'), throwsStateError),
  );

  test(
    'an address without a trailing slash is refused',
    () => expect(() => requireContentBaseUrl('https://example.org'), throwsStateError),
  );

  test(
    'a refusal names the define and the rule',
    () => expect(
      () => requireContentBaseUrl('https://example.org'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('CONTENT_BASE_URL'), contains('https://'), contains('slash')),
        ),
      ),
    ),
  );

  test(
    'a valid address is returned',
    () => expect(requireContentBaseUrl('https://example.org/bazaar/'), 'https://example.org/bazaar/'),
  );
}
