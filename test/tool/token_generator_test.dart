import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../tool/src/token_generator.dart';

const _base = {'--color-slab-on-surface': '#e7e3d8ff'};

String tokens(Map<String, String> light, {Map<String, String>? dark}) => jsonEncode({
  'schemaVersion': 1,
  'light': {..._base, ...light},
  'dark': {..._base, ...(dark ?? light)},
});

Matcher _throwsNaming(String name) =>
    throwsA(isA<ArgumentError>().having((e) => '${e.message}', 'message', startsWith(name)));

void main() {
  test('a colour that differs between the themes is a BazaarColors field, in token order', () {
    final out = generateTokens(
      tokens(
        {'--color-surface': '#fdfbf7ff', '--color-on-surface-muted': '#6a6558ff'},
        dark: {'--color-surface': '#1d1f27ff', '--color-on-surface-muted': '#9aa0adff'},
      ),
    );
    expect(
      out,
      contains(
        '  static const BazaarColors light = BazaarColors(surface: Color(0xfffdfbf7), onSurfaceMuted: Color(0xff6a6558));',
      ),
    );
    expect(
      out,
      contains(
        '  static const BazaarColors dark = BazaarColors(surface: Color(0xff1d1f27), onSurfaceMuted: Color(0xff9aa0ad));',
      ),
    );
    expect(out, contains('final class BazaarColors extends ThemeExtension<BazaarColors> {'));
  });

  test('a colour equal in both themes is a BazaarFixedColors const', () {
    expect(
      generateTokens(tokens({'--color-bar-hover': '#ffffff1a'})),
      contains('  static const Color barHover = Color(0x1affffff);'),
    );
  });

  test('slab colours are looked up by suffix and an unknown or absent role draws in on-surface', () {
    final out = generateTokens(tokens({'--color-slab-keyword': '#c48ce0ff'}));
    expect(out, contains("    'keyword': BazaarFixedColors.slabKeyword,"));
    expect(out, contains('  static Color forRole(String? role) => bySuffix[role] ?? BazaarFixedColors.slabOnSurface;'));
  });

  test('a text step takes its line height, before or after it, and may have none', () {
    final out = generateTokens(
      tokens({'--text-body--line-height': '1.68', '--text-body': '16px', '--text-label': '12px'}),
    );
    expect(out, contains('  static const TypeStep body = TypeStep(size: 16, height: 1.68);'));
    expect(out, contains('  static const TypeStep label = TypeStep(size: 12);'));
    final after = generateTokens(tokens({'--text-body': '16px', '--text-body--line-height': '1.68'}));
    expect(after, contains('  static const TypeStep body = TypeStep(size: 16, height: 1.68);'));
  });

  test('tracking is an em factor', () {
    expect(
      generateTokens(tokens({'--tracking-label': '0.06em'})),
      contains('  static const double trackingLabel = 0.06;'),
    );
    expect(
      generateTokens(tokens({'--tracking-display': '-0.015em'})),
      contains('  static const double trackingDisplay = -0.015;'),
    );
  });

  test('radius, shape, duration, ease and layout take their Dart forms', () {
    final out = generateTokens(
      tokens({
        '--radius-sm': '4px',
        '--shape-arch': '14px 14px 4px 4px',
        '--duration-swift': '120ms',
        '--ease-bazaar': 'cubic-bezier(0.22, 0.61, 0.36, 1)',
        '--layout-bar': '58px',
      }),
    );
    expect(out, contains('  static const Radius sm = Radius.circular(4);'));
    expect(
      out,
      contains(
        '  static const BorderRadius arch = BorderRadius.only(\n    topLeft: Radius.circular(14),\n'
        '    topRight: Radius.circular(14),\n    bottomRight: Radius.circular(4),\n    bottomLeft: Radius.circular(4),\n  );',
      ),
    );
    expect(out, contains('  static const Duration swift = Duration(milliseconds: 120);'));
    expect(out, contains('  static const Cubic bazaar = Cubic(0.22, 0.61, 0.36, 1);'));
    expect(out, contains('  static const double bar = 58;'));
  });

  test('a shadow reads rgba() and rounds the alpha as the web does', () {
    final out = generateTokens(
      tokens({
        '--shadow-menu': '0 12px 28px rgba(40, 30, 10, 0.13)',
        '--shadow-tab': '2px 0 10px rgba(40, 30, 10, 0.10)',
      }),
    );
    expect(
      out,
      contains(
        '  static const List<BoxShadow> menu = '
        '[BoxShadow(color: Color(0x21281e0a), offset: Offset(0, 12), blurRadius: 28)];',
      ),
    );
    expect(
      out,
      contains(
        '  static const List<BoxShadow> tab = '
        '[BoxShadow(color: Color(0x1a281e0a), offset: Offset(2, 0), blurRadius: 10)];',
      ),
    );
  });

  test('a shadow of several layers, with rgb() and #rrggbbaa colours, is one BoxShadow per layer', () {
    final out = generateTokens(tokens({'--shadow-x': '0 1px 2px rgb(1, 2, 3), 0 0 4px #0a0b0c80'}));
    expect(out, contains('BoxShadow(color: Color(0xff010203), offset: Offset(0, 1), blurRadius: 2)'));
    expect(out, contains('BoxShadow(color: Color(0x800a0b0c), offset: Offset(0, 0), blurRadius: 4)'));
  });

  for (final name in ['--font-sans', '--layout-fold-at', '--layout-measure', '--layout-rail', '--layout-aside']) {
    test('$name is skipped, with its reason', () {
      final reason = skippedTokenReasons.entries.singleWhere((e) => RegExp(e.key).hasMatch(name)).value;
      expect(reason, isNotEmpty);
      expect(generateTokens(tokens({name: '1px'})), generateTokens(tokens({})));
    });
  }

  test('a token whose prefix has no rule throws, naming it', () {
    for (final name in ['--space-sm', '--layout-gutter']) {
      expect(() => generateTokens(tokens({name: '4px'})), _throwsNaming(name));
      expect(
        () => generateTokens(tokens({name: '4px'})),
        throwsA(isA<ArgumentError>().having((e) => '${e.message}', 'message', '$name: no rule for this prefix')),
      );
    }
  });

  test('a colour that is not #rrggbbaa throws, naming the token', () {
    for (final value in ['oklch(0.5 0.1 200)', '#fff', '#FDFBF7FF', 'white']) {
      expect(() => generateTokens(tokens({'--color-x': value})), _throwsNaming('--color-x'));
    }
  });

  test('a non-colour token that differs between the themes throws, naming it', () {
    expect(
      () => generateTokens(tokens({'--radius-sm': '4px'}, dark: {'--radius-sm': '5px'})),
      _throwsNaming('--radius-sm'),
    );
  });

  test('a skipped token that differs between the themes throws, naming it', () {
    expect(
      () => generateTokens(tokens({'--font-sans': 'a'}, dark: {'--font-sans': 'b'})),
      _throwsNaming('--font-sans'),
    );
  });

  test('a slab colour that differs between the themes throws, naming it', () {
    expect(
      () => generateTokens(tokens({'--color-slab-keyword': '#c48ce0ff'}, dark: {'--color-slab-keyword': '#000000ff'})),
      _throwsNaming('--color-slab-keyword'),
    );
  });

  test('a dark key list unlike the light one throws, naming the field', () {
    expect(() => generateTokens(tokens({'--radius-sm': '4px'}, dark: {'--radius-md': '4px'})), _throwsNaming('dark'));
    expect(
      () => generateTokens(
        tokens({'--radius-sm': '4px', '--radius-md': '6px'}, dark: {'--radius-md': '6px', '--radius-sm': '4px'}),
      ),
      _throwsNaming('dark'),
    );
  });

  test('a schemaVersion other than 1 or a top-level key other than the three throws, naming the field', () {
    final good = jsonDecode(tokens({})) as Map<String, Object?>;
    expect(() => generateTokens(jsonEncode({...good, 'schemaVersion': 2})), _throwsNaming('schemaVersion'));
    expect(() => generateTokens(jsonEncode({...good, 'extra': 1})), _throwsNaming('extra'));
    expect(() => generateTokens(jsonEncode({'schemaVersion': 1, 'light': good['light']})), _throwsNaming('dark'));
  });

  test('a token value of the wrong form throws, naming the token', () {
    const cases = {
      '--tracking-x': '1px',
      '--duration-x': '0.2s',
      '--ease-x': 'ease-in',
      '--text-x': '1rem',
      '--radius-x': '4',
      '--shape-x': '4px 4px',
      '--layout-bar': '58',
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(() => generateTokens(tokens({key: value})), _throwsNaming(key), reason: '$key: $value');
    }
  });

  test('a line height without its text step throws, naming it', () {
    expect(() => generateTokens(tokens({'--text-x--line-height': '1.5'})), _throwsNaming('--text-x--line-height'));
  });

  test('an inset shadow or a shadow with a spread throws, naming it', () {
    for (final value in ['inset 0 1px 2px rgba(0, 0, 0, 0.1)', '0 1px 2px 3px rgba(0, 0, 0, 0.1)']) {
      expect(() => generateTokens(tokens({'--shadow-x': value})), _throwsNaming('--shadow-x'), reason: value);
    }
  });

  test('a name that is a Dart reserved word or not lowerCamelCase throws, naming the token', () {
    expect(() => generateTokens(tokens({'--radius-default': '4px'})), _throwsNaming('--radius-default'));
    expect(() => generateTokens(tokens({'--radius-Big': '4px'})), _throwsNaming('--radius-Big'));
    expect(() => generateTokens(tokens({'--radius-1x': '4px'})), _throwsNaming('--radius-1x'));
  });

  test('two tokens that become the same Dart name throw, naming the second', () {
    expect(
      () => generateTokens(tokens({'--radius-category-1': '4px', '--radius-category1': '5px'})),
      _throwsNaming('--radius-category1'),
    );
  });

  test('input without --color-slab-on-surface throws, naming it', () {
    expect(
      () => generateTokens(jsonEncode({'schemaVersion': 1, 'light': <String, String>{}, 'dark': <String, String>{}})),
      _throwsNaming('--color-slab-on-surface'),
    );
  });

  test('the output is already formatted', () {
    final out = generateTokens(tokens({'--color-bar': '#282864ff', '--text-body': '16px'}));
    expect(DartFormatter(languageVersion: Version(3, 13, 0), pageWidth: 120).format(out), out);
  });

  test('the output with every kind of token is already formatted and empty classes are still emitted', () {
    final empty = generateTokens(tokens({}));
    for (final name in [
      'BazaarColors',
      'BazaarFixedColors',
      'BazaarSlab',
      'BazaarType',
      'BazaarRadii',
      'BazaarShapes',
      'BazaarMotion',
      'BazaarShadows',
      'BazaarLayout',
    ]) {
      expect(empty, contains(' class $name '));
    }
    final out = generateTokens(
      tokens(
        {
          '--color-surface': '#fdfbf7ff',
          '--color-bar': '#282864ff',
          '--text-body': '16px',
          '--tracking-label': '0.06em',
          '--radius-sm': '4px',
          '--shape-leaf': '4px 14px 4px 14px',
          '--duration-fold': '200ms',
          '--ease-bazaar': 'cubic-bezier(0.22, 0.61, 0.36, 1)',
          '--shadow-tab': '2px 0 10px rgba(40, 30, 10, 0.10)',
          '--layout-sticky': '76px',
        },
        dark: {
          '--color-surface': '#1d1f27ff',
          '--color-bar': '#282864ff',
          '--text-body': '16px',
          '--tracking-label': '0.06em',
          '--radius-sm': '4px',
          '--shape-leaf': '4px 14px 4px 14px',
          '--duration-fold': '200ms',
          '--ease-bazaar': 'cubic-bezier(0.22, 0.61, 0.36, 1)',
          '--shadow-tab': '2px 0 10px rgba(40, 30, 10, 0.10)',
          '--layout-sticky': '76px',
        },
      ),
    );
    final formatter = DartFormatter(languageVersion: Version(3, 13, 0), pageWidth: 120);
    expect(formatter.format(empty), empty);
    expect(formatter.format(out), out);
    expect(
      out,
      startsWith('// GENERATED by tool/generate_tokens.dart from the bundled api/v1/tokens.json. Do not edit.\n'),
    );
  });

  group('readBundledTokensJson', () {
    late Directory root;
    const body = '{"t":1}';
    final sha = sha256.convert(utf8.encode(body)).toString();

    setUp(() {
      root = Directory.systemTemp.createTempSync('tokens_');
      Directory('${root.path}/assets/content/objects').createSync(recursive: true);
    });
    tearDown(() => root.deleteSync(recursive: true));

    void write({Map<String, String>? files, String object = body}) {
      File('${root.path}/assets/content/index.json').writeAsStringSync(
        jsonEncode({
          'files': files ?? {'api/v1/tokens.json': sha},
        }),
      );
      File('${root.path}/assets/content/objects/$sha').writeAsStringSync(object);
    }

    test('reads tokens.json through the index', () {
      write();
      expect(readBundledTokensJson(root.path), body);
    });

    test('throws when the object does not hash to its name, naming the sha256', () {
      write(object: '{"t":2}');
      expect(
        () => readBundledTokensJson(root.path),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains(sha))),
      );
    });

    test('throws when the index does not name tokens.json', () {
      write(files: {'api/v1/other.json': sha});
      expect(
        () => readBundledTokensJson(root.path),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('api/v1/tokens.json'))),
      );
    });
  });
}
