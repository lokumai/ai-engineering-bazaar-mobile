import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled snapshot (spec 3.4.1) is declared as assets, so the app can read it. It states no fact about the course.
void main() {
  test('the bundled index, api index and objects are assets of the app', () async {
    final majors = jsonDecode(await rootBundle.loadString('assets/content/api_index.json')) as Map<String, Object?>;
    expect(majors['majors'], contains(1));
    final index = jsonDecode(await rootBundle.loadString('assets/content/index.json')) as Map<String, Object?>;
    final sha = (index['files']! as Map<String, Object?>)['api/v1/tokens.json']! as String;
    final bytes = await rootBundle.load('assets/content/objects/$sha');
    expect(sha256.convert(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)).toString(), sha);
  });
}
