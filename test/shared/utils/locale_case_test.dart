import 'package:ai_engineering_bazaar/shared/utils/locale_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Turkish keeps the dot on a capital i and drops it from a capital ı', () {
    expect(upperCaseIn('Sıradaki', 'tr'), 'SIRADAKİ');
    expect(upperCaseIn('Bu sayfada', 'tr'), 'BU SAYFADA');
    expect(upperCaseIn('içindekiler', 'tr'), 'İÇİNDEKİLER');
  });

  test('other languages capitalise as Dart does', () {
    expect(upperCaseIn('Up next', 'en'), 'UP NEXT');
    expect(upperCaseIn('in this file', 'en'), 'IN THIS FILE');
    expect(upperCaseIn('در این صفحه', 'fa'), 'در این صفحه');
  });
}
