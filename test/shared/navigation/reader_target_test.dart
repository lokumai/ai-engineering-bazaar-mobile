@Tags(['unit'])
library;

import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a route extra names a target, a heading id, or nothing', () {
    const target = ReaderTarget(fragment: 'one', query: 'agent');
    expect(ReaderTarget.of(target), same(target));

    final link = ReaderTarget.of('two');
    expect((link.fragment, link.query), ('two', null));

    final none = ReaderTarget.of(null);
    expect((none.fragment, none.query), (null, null));
  });
}
