import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards that every ARB file beside the template that `pubspec.yaml` names has the template's messages, no others,
/// and uses every placeholder the template declares.
///
/// intl_utils generates `S` from the template and looks each message up by name in the other files, so a message
/// missing from one still compiles and that language shows it from the template without any error. A translation that
/// leaves out a placeholder drops that value from the text.
///
/// While English is the only language (spec 3.9) there is no other ARB file, so the per-language checks hold
/// vacuously; the first test keeps the guard reading the template.
void main() {
  final templatePath = RegExp(
    r'^\s*template-arb-file:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1);
  Map<String, dynamic> read(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  Set<String> messages(Map<String, dynamic> arb) => {
    for (final key in arb.keys)
      if (!key.startsWith('@')) key,
  };

  final template = read(templatePath!);
  final translations = [
    for (final file in File(templatePath).parent.listSync().whereType<File>())
      if (file.path.endsWith('.arb') && file.path != templatePath) file.path,
  ]..sort();

  test('the template ARB is the one pubspec.yaml names, and it holds messages', () {
    expect(templatePath, 'lib/l10n/intl_en.arb');
    expect(messages(template), contains('app_title'));
  });

  for (final path in translations) {
    final translation = read(path);

    test('$path has the same messages as $templatePath', () {
      expect(
        messages(template).difference(messages(translation)),
        isEmpty,
        reason: 'these messages of $templatePath are missing from $path',
      );
      expect(
        messages(translation).difference(messages(template)),
        isEmpty,
        reason: 'these messages of $path are not in $templatePath',
      );
    });

    test('each message of $path uses every placeholder that $templatePath declares', () {
      final missing = [
        for (final key in messages(template).intersection(messages(translation)))
          for (final name
              in ((template['@$key'] as Map<String, dynamic>?)?['placeholders'] as Map<String, dynamic>?)?.keys ??
                  const <String>[])
            if (!RegExp('\\{$name[,}]').hasMatch(translation[key] as String)) '$key: {$name}',
      ];
      expect(missing, isEmpty, reason: 'these messages of $path leave out a placeholder');
    });
  }
}
