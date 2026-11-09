import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Turns the snapshot's `api/v1/tokens.json` into `lib/shared/design_system/bazaar_tokens.g.dart` (spec 3.8).
///
/// Pure Dart, no Flutter import, so `fvm dart run tool/generate_tokens.dart` runs it. Every token either has a rule
/// below or is skipped with its reason; anything else throws an [ArgumentError] whose message starts with the token
/// name, so a new token on the web stops the generator instead of being dropped.

/// RegExp source -> the reason the app does not take the token.
const Map<String, String> skippedTokenReasons = {
  r'^--font-':
      'Fonts are platform choices: Avenir Next and Menlo on iOS, the platform default and monospace on Android '
      '(bazaar_fonts.dart).',
  r'^--layout-.+-at$': 'A web breakpoint; the app lays out one column at every width.',
  r'^--layout-measure$': 'A web reading measure in ch; the app column is the width of the screen.',
  r'^--layout-rail$': 'A web column the app does not have.',
  r'^--layout-aside$': 'A web column the app does not have.',
};

const _tokensKey = 'api/v1/tokens.json';

/// Reads `tokens.json` from the bundled snapshot under [root]: `assets/content/index.json` names its sha256 in
/// `files['api/v1/tokens.json']`, and `assets/content/objects/<sha256>` holds the bytes, which must hash to the name.
String readBundledTokensJson(String root) {
  final index = jsonDecode(File('$root/assets/content/index.json').readAsStringSync());
  final files = index is Map<String, Object?> ? index['files'] : null;
  final sha = files is Map<String, Object?> ? files[_tokensKey] : null;
  if (sha is! String) throw StateError('assets/content/index.json names no $_tokensKey in files');
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) throw StateError('$_tokensKey names $sha, which is not a sha256');
  final bytes = File('$root/assets/content/objects/$sha').readAsBytesSync();
  if (sha256.convert(bytes).toString() != sha) {
    throw StateError('assets/content/objects/$sha does not hash to its name; refresh the snapshot');
  }
  return utf8.decode(bytes);
}

const _reservedWords = {
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'while',
  'with',
};

/// Members of [ThemeExtension] and [Object] a `BazaarColors` field would hide.
const _themeExtensionMembers = {'copyWith', 'lerp', 'type', 'light', 'dark', 'hashCode', 'runtimeType', 'toString'};

const _number = r'-?\d+(?:\.\d+)?';
final _colour = RegExp(r'^#([0-9a-f]{6})([0-9a-f]{2})$');
final _px = RegExp('^($_number)px\$');
final _em = RegExp('^($_number)em\$');
final _unitless = RegExp('^($_number)\$');
final _ms = RegExp(r'^(\d+)ms$');
final _cubic = RegExp(
  '^cubic-bezier\\(\\s*($_number)\\s*,\\s*($_number)\\s*,\\s*($_number)\\s*,\\s*($_number)\\s*\\)\$',
);
final _rgba = RegExp(r'^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*(' + _number + r')\s*)?\)$');
final _lineHeight = RegExp(r'^--text-(.+)--line-height$');
final _layout = RegExp(r'^--layout-(bar|band|sticky)$');

/// One class of the generated file: its members in token order, each a full declaration.
final class _Members {
  final names = <String>{};
  final lines = <String>[];

  void add(String token, String name, String declaration) {
    if (!names.add(name)) throw ArgumentError('$token: becomes $name, which an earlier token already is');
    lines.add(declaration);
  }
}

/// Generates the Dart source of `bazaar_tokens.g.dart` from [tokensJson], formatted as `dart format` at width 120.
String generateTokens(String tokensJson) {
  final (light, dark) = _themes(jsonDecode(tokensJson));

  final colours = <({String name, String light, String dark})>[];
  final colourNames = <String>{};
  final fixed = _Members();
  final slab = <String>[];
  final type = _Members();
  final radii = _Members();
  final shapes = _Members();
  final motion = _Members();
  final shadows = _Members();
  final layout = _Members();

  final lineHeights = <String, ({String token, String value})>{};
  for (final MapEntry(key: token, :value) in light.entries) {
    if (_lineHeight.firstMatch(token) case final match? when !_skipped(token)) {
      if (value != dark[token]) throw ArgumentError('$token: differs between the themes');
      lineHeights[match.group(1)!] = (token: token, value: _match(_unitless, token, value, 'a unitless number')[1]!);
    }
  }
  final steps = <String>{};

  for (final MapEntry(key: token, :value) in light.entries) {
    final darkValue = dark[token]!;
    if (_skipped(token)) {
      if (value != darkValue) throw ArgumentError('$token: differs between the themes');
      continue;
    }
    if (token.startsWith('--color-')) {
      final lightColour = _colourOf(token, value);
      final darkColour = _colourOf(token, darkValue);
      final rest = token.substring('--color-'.length);
      if (rest.startsWith('slab-')) {
        if (value != darkValue) throw ArgumentError('$token: a slab colour differs between the themes');
        final suffix = rest.substring('slab-'.length);
        final name = _name(token, rest);
        fixed.add(token, name, 'static const Color $name = $lightColour;');
        slab.add("'$suffix': BazaarFixedColors.$name,");
      } else if (value != darkValue) {
        final name = _name(token, rest);
        if (_themeExtensionMembers.contains(name)) throw ArgumentError('$token: $name is a member of ThemeExtension');
        if (!colourNames.add(name) || fixed.names.contains(name)) {
          throw ArgumentError('$token: becomes $name, which an earlier token already is');
        }
        colours.add((name: name, light: lightColour, dark: darkColour));
      } else {
        final name = _name(token, rest);
        if (colourNames.contains(name)) throw ArgumentError('$token: becomes $name, which an earlier token already is');
        fixed.add(token, name, 'static const Color $name = $lightColour;');
      }
      continue;
    }
    if (value != darkValue) throw ArgumentError('$token: differs between the themes');
    if (_lineHeight.hasMatch(token)) continue;
    if (token.startsWith('--text-')) {
      final step = token.substring('--text-'.length);
      final size = _match(_px, token, value, '<number>px')[1]!;
      final height = lineHeights[step];
      steps.add(step);
      final name = _name(token, step);
      type.add(
        token,
        name,
        'static const TypeStep $name = TypeStep(size: $size, ${height == null ? '' : 'height: ${height.value},'});',
      );
    } else if (token.startsWith('--tracking-')) {
      final factor = _match(_em, token, value, '<number>em')[1]!;
      final name = _name(token, 'tracking-${token.substring('--tracking-'.length)}');
      type.add(token, name, 'static const double $name = $factor;');
    } else if (token.startsWith('--radius-')) {
      final radius = _match(_px, token, value, '<number>px')[1]!;
      final name = _name(token, token.substring('--radius-'.length));
      radii.add(token, name, 'static const Radius $name = Radius.circular($radius);');
    } else if (token.startsWith('--shape-')) {
      final corners = value.split(' ');
      if (corners.length != 4) throw ArgumentError('$token: "$value" is not four lengths');
      final [topLeft, topRight, bottomRight, bottomLeft] = [
        for (final corner in corners) _match(_px, token, corner, '<number>px')[1]!,
      ];
      final name = _name(token, token.substring('--shape-'.length));
      shapes.add(
        token,
        name,
        'static const BorderRadius $name = BorderRadius.only(topLeft: Radius.circular($topLeft), '
        'topRight: Radius.circular($topRight), bottomRight: Radius.circular($bottomRight), '
        'bottomLeft: Radius.circular($bottomLeft),);',
      );
    } else if (token.startsWith('--duration-')) {
      final ms = _match(_ms, token, value, '<integer>ms')[1]!;
      final name = _name(token, token.substring('--duration-'.length));
      motion.add(token, name, 'static const Duration $name = Duration(milliseconds: $ms);');
    } else if (token.startsWith('--ease-')) {
      final match = _match(_cubic, token, value, 'cubic-bezier(a, b, c, d)');
      final name = _name(token, token.substring('--ease-'.length));
      motion.add(token, name, 'static const Cubic $name = Cubic(${match[1]}, ${match[2]}, ${match[3]}, ${match[4]},);');
    } else if (token.startsWith('--shadow-')) {
      final layers = [for (final layer in _splitOutside(value, ',')) _shadowLayer(token, layer.trim())];
      final name = _name(token, token.substring('--shadow-'.length));
      shadows.add(token, name, 'static const List<BoxShadow> $name = [${layers.join()}];');
    } else if (_layout.firstMatch(token) case final match?) {
      final length = _match(_px, token, value, '<number>px')[1]!;
      layout.add(token, match[1]!, 'static const double ${match[1]} = $length;');
    } else {
      throw ArgumentError('$token: no rule for this prefix');
    }
  }

  for (final MapEntry(key: step, value: (:token, value: _)) in lineHeights.entries) {
    if (!steps.contains(step)) throw ArgumentError('$token: there is no --text-$step');
  }
  if (!slab.any((entry) => entry.startsWith("'on-surface':"))) {
    throw ArgumentError('--color-slab-on-surface: required, the ink of a code token with no role');
  }

  final source = StringBuffer()
    ..writeln('// GENERATED by tool/generate_tokens.dart from the bundled api/v1/tokens.json. Do not edit.')
    ..writeln('// Regenerate: fvm dart run tool/generate_tokens.dart')
    ..writeln()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln("import 'type_step.dart';")
    ..writeln()
    ..write(_colourExtension(colours))
    ..write(_class('The colours equal in both themes, the code slab among them.', 'BazaarFixedColors', fixed.lines))
    ..write(
      _class(
        'The code slab colours by the text after --color-slab-, the bundle\'s code token roles among them.',
        'BazaarSlab',
        [
          'static const Map<String, Color> bySuffix = {${slab.join()}};',
          '/// The colour of a code token with [role]; no role, or one without a slab colour, draws in on-surface.',
          'static Color forRole(String? role) => bySuffix[role] ?? BazaarFixedColors.slabOnSurface;',
        ],
      ),
    )
    ..write(
      _class(
        'The --text-* steps, and the --tracking-* em factors a style multiplies by its own font size.',
        'BazaarType',
        type.lines,
      ),
    )
    ..write(_class('The --radius-* corners.', 'BazaarRadii', radii.lines))
    ..write(
      _class(
        'The --shape-* corners, in CSS order: top left, top right, bottom right, bottom left.',
        'BazaarShapes',
        shapes.lines,
      ),
    )
    ..write(_class('The --duration-* and --ease-* motion.', 'BazaarMotion', motion.lines))
    ..write(_class('The --shadow-* layers.', 'BazaarShadows', shadows.lines))
    ..write(_class('The --layout-* lengths the app takes.', 'BazaarLayout', layout.lines));
  return DartFormatter(languageVersion: Version(3, 13, 0), pageWidth: 120).format(source.toString());
}

(Map<String, String>, Map<String, String>) _themes(Object? decoded) {
  if (decoded is! Map<String, Object?>) throw ArgumentError('tokens.json: not a JSON object');
  for (final key in decoded.keys) {
    if (key != 'schemaVersion' && key != 'light' && key != 'dark') throw ArgumentError('$key: not a tokens.json key');
  }
  if (decoded['schemaVersion'] != 1) throw ArgumentError('schemaVersion: ${decoded['schemaVersion']} is not 1');
  final light = _theme('light', decoded['light']);
  final dark = _theme('dark', decoded['dark']);
  final lightKeys = light.keys.toList();
  final darkKeys = dark.keys.toList();
  if (lightKeys.length != darkKeys.length ||
      [for (var i = 0; i < lightKeys.length; i++) lightKeys[i] == darkKeys[i]].contains(false)) {
    throw ArgumentError('dark: its tokens are not the light tokens in the same order');
  }
  return (light, dark);
}

Map<String, String> _theme(String field, Object? value) {
  if (value is! Map<String, Object?>) throw ArgumentError('$field: not a JSON object');
  return {
    for (final MapEntry(:key, :value) in value.entries)
      key: value is String ? value : throw ArgumentError('$key: the $field value is not a string'),
  };
}

bool _skipped(String token) => skippedTokenReasons.keys.any((source) => RegExp(source).hasMatch(token));

RegExpMatch _match(RegExp pattern, String token, String value, String form) =>
    pattern.firstMatch(value) ?? (throw ArgumentError('$token: "$value" is not $form'));

String _colourOf(String token, String value) {
  final match = _match(_colour, token, value, '#rrggbbaa');
  return 'Color(0x${match[2]}${match[1]})';
}

/// The text after the prefix in lowerCamelCase: `on-surface-muted` -> `onSurfaceMuted`, `category-1` -> `category1`.
String _name(String token, String rest) {
  final parts = rest.split('-');
  final name = [
    parts.first,
    for (final part in parts.skip(1)) part.isEmpty ? '-' : part[0].toUpperCase() + part.substring(1),
  ].join();
  if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(name)) {
    throw ArgumentError('$token: "$name" is not a lowerCamelCase name');
  }
  if (_reservedWords.contains(name)) throw ArgumentError('$token: "$name" is a Dart reserved word');
  return name;
}

/// Splits [value] at each [separator] that is outside parentheses.
List<String> _splitOutside(String value, String separator) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (char == separator && depth == 0) {
      parts.add(value.substring(start, i));
      start = i + 1;
    }
  }
  return [...parts, value.substring(start)];
}

/// One layer `<x> <y> <blur> <colour>`; `inset`, a spread length or any other shape throws.
String _shadowLayer(String token, String layer) {
  final words = _splitOutside(layer, ' ').where((word) => word.isNotEmpty).toList();
  if (words.contains('inset')) throw ArgumentError('$token: an inset shadow has no BoxShadow form');
  if (words.length != 4) throw ArgumentError('$token: "$layer" is not <x> <y> <blur> <colour>');
  final [x, y, blur] = [
    for (final word in words.take(3)) word == '0' ? '0' : _match(_px, token, word, 'a length in px or 0')[1]!,
  ];
  return 'BoxShadow(color: ${_shadowColour(token, words[3])}, offset: Offset($x, $y), blurRadius: $blur,),';
}

String _shadowColour(String token, String value) {
  if (value.startsWith('#')) return _colourOf(token, value);
  final match = _match(_rgba, token, value, 'rgba(r, g, b, a), rgb(r, g, b) or #rrggbbaa');
  final rgb = [for (var i = 1; i <= 3; i++) int.parse(match[i]!)];
  if (rgb.any((channel) => channel > 255)) throw ArgumentError('$token: "$value" has a channel above 255');
  final alpha = match[4] == null ? 1.0 : double.parse(match[4]!);
  if (alpha < 0 || alpha > 1) throw ArgumentError('$token: "$value" has an alpha outside 0 to 1');
  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
  return 'Color(0x${hex((alpha * 255).round())}${rgb.map(hex).join()})';
}

String _class(String doc, String name, List<String> members) =>
    '/// $doc\nabstract final class $name {\n${members.join('\n')}\n}\n\n';

String _colourExtension(List<({String name, String light, String dark})> colours) {
  String call(String Function(String name) argument) =>
      'BazaarColors(${[for (final c in colours) '${c.name}: ${argument(c.name)},'].join()})';
  final lightValues = {for (final c in colours) c.name: c.light};
  final darkValues = {for (final c in colours) c.name: c.dark};
  final constructor = colours.isEmpty
      ? 'const BazaarColors();'
      : 'const BazaarColors({${[for (final c in colours) 'required this.${c.name},'].join()}});';
  final copyWithParameters = colours.isEmpty ? '' : '{${[for (final c in colours) 'Color? ${c.name},'].join()}}';
  return '''
/// The colours whose light and dark values differ, as a theme extension.
final class BazaarColors extends ThemeExtension<BazaarColors> {
$constructor

static const BazaarColors light = ${call((name) => lightValues[name]!)};
static const BazaarColors dark = ${call((name) => darkValues[name]!)};

${[for (final c in colours) 'final Color ${c.name};'].join('\n')}

@override
BazaarColors copyWith($copyWithParameters) => ${call((name) => '$name ?? this.$name')};

@override
BazaarColors lerp(BazaarColors? other, double t) {
if (other == null) return this;
return ${call((name) => 'Color.lerp($name, other.$name, t)!')};
}
}

''';
}
