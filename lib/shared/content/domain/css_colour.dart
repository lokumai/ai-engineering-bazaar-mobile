import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';

final RegExp _hex = RegExp(r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');

/// Reads the CSS colour text of `diagramThemes.<variant>.background` as an opaque ARGB value.
///
/// Accepts exactly `white`, `#rgb` and `#rrggbb` (hex digits in either case); anything else throws
/// `ContentFormatException(path, 'colour')`.
int parseCssColour(String text, {required String path}) {
  if (text == 'white') return 0xFFFFFFFF;
  if (!_hex.hasMatch(text)) throw ContentFormatException(path, 'colour');
  final digits = text.substring(1);
  final rgb = digits.length == 3 ? digits.split('').map((digit) => '$digit$digit').join() : digits;
  return 0xFF000000 | int.parse(rgb, radix: 16);
}
