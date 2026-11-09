import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies the architectural dependency rules of CLAUDE.md:
///
/// - `app/` -> features, shared, infrastructure, core
/// - `features/` -> shared, infrastructure, core (NOT other features' internals, NOT `app/` apart from the known
///   exception below)
/// - `shared/` -> core only (NO features, app or infrastructure imports)
/// - `core/` -> nothing (NO shared, features, infrastructure or app imports)
/// - `infrastructure/` -> NO features or app imports
///
/// The rules read every single-quoted `import` and `export` line of `lib/` (outside `lib/generated/`) that names this
/// package, whose name comes from `pubspec.yaml`. Two self-checks keep them from passing vacuously: at least one
/// import of the package must be read, and no `import`, `export` or `part` directive may use double quotes.
///
/// It also keeps url_launcher behind `shared/utils/external_link.dart`, so every link tells the user when it does not
/// open.

/// Known exception: features/ may import the route constants of app/.
const _knownFeatureAppExceptions = {
  'app/router/app_routes_constants', // settings_routes.dart navigates by these constants
};

void main() {
  group('Architecture Guard Tests', () {
    late List<File> dartFiles;
    late String packageName;

    setUpAll(() {
      packageName = _readPackageName();
      final libDir = Directory('lib');
      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('/generated/'))
          .toList();
    });

    test('core/ must not import from shared/, features/, infrastructure/, or app/', () {
      final violations = <String>[];
      final coreFiles = dartFiles.where((f) => f.path.contains('/core/'));

      for (final file in coreFiles) {
        for (final import in _getImports(file, packageName)) {
          if (import.path.contains('/shared/') ||
              import.path.contains('/features/') ||
              import.path.contains('/infrastructure/') ||
              import.path.contains('/app/')) {
            violations.add('${_relative(file.path)}: imports ${import.path}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'core/ must have zero dependencies on other layers:\n${violations.join('\n')}',
      );
    });

    test('shared/ must not import from features/ or app/', () {
      final violations = <String>[];
      final sharedFiles = dartFiles.where((f) => f.path.contains('/shared/'));

      for (final file in sharedFiles) {
        for (final import in _getImports(file, packageName)) {
          if (import.path.contains('/features/') || import.path.contains('/app/')) {
            violations.add('${_relative(file.path)}: imports ${import.path}');
          }
        }
      }

      expect(violations, isEmpty, reason: 'shared/ must not import from features/ or app/:\n${violations.join('\n')}');
    });

    test('features/ must not import from other features/ internals', () {
      final violations = <String>[];
      final featureFiles = dartFiles.where((f) => f.path.contains('/features/'));

      for (final file in featureFiles) {
        final featureName = _extractFeatureName(file.path);
        if (featureName == null) continue;

        for (final import in _getImports(file, packageName)) {
          if (!import.path.contains('/features/')) continue;

          final importedFeature = _extractFeatureNameFromImport(import.path);
          if (importedFeature != null && importedFeature != featureName && !import.path.contains('/shared/')) {
            violations.add('${_relative(file.path)} ($featureName) imports from $importedFeature: ${import.path}');
          }
        }
      }

      expect(violations, isEmpty, reason: 'features must not import from other features:\n${violations.join('\n')}');
    });

    test('features/ must not import from app/', () {
      final violations = <String>[];
      final featureFiles = dartFiles.where((f) => f.path.contains('/features/'));

      for (final file in featureFiles) {
        for (final import in _getImports(file, packageName)) {
          if (import.path.contains('/app/')) {
            final fragment = _importFragment(import.path, packageName);
            if (!_knownFeatureAppExceptions.any((e) => fragment.contains(e))) {
              violations.add('${_relative(file.path)}: imports ${import.path}');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'features/ must not import from app/:\n${violations.join('\n')}');
    });

    test('infrastructure/ must not import from features/ or app/', () {
      final violations = <String>[];
      final infraFiles = dartFiles.where((f) => f.path.contains('/infrastructure/'));

      for (final file in infraFiles) {
        for (final import in _getImports(file, packageName)) {
          if (import.path.contains('/features/') || import.path.contains('/app/')) {
            violations.add('${_relative(file.path)}: imports ${import.path}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'infrastructure/ must not import from features/ or app/:\n${violations.join('\n')}',
      );
    });

    test('only shared/utils/external_link.dart imports url_launcher', () {
      final urlLauncherImport = RegExp(r'''^import\s+['"]package:url_launcher/''');
      final violations = dartFiles
          .where((f) => _relative(f.path) != 'lib/shared/utils/external_link.dart')
          .where((f) => f.readAsLinesSync().any(urlLauncherImport.hasMatch))
          .map((f) => _relative(f.path))
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'Open links with openExternalLink, which tells the user when a link does not open. A direct url_launcher '
            'call can fail without a word, and canLaunchUrl answers false for https links on Android 11 and higher, '
            'because the manifest declares no <queries> intent for them:\n${violations.join('\n')}',
      );
    });

    test('shared/ must not import from infrastructure/', () {
      final violations = [
        for (final file in dartFiles.where((f) => f.path.contains('/shared/')))
          for (final import in _getImports(file, packageName))
            if (import.path.contains('/infrastructure/')) '${_relative(file.path)}: imports ${import.path}',
      ];
      expect(violations, isEmpty, reason: 'shared/ must not import from infrastructure/:\n${violations.join('\n')}');
    });

    test('the guard reads the package name from pubspec.yaml and sees its package imports', () {
      expect(packageName, isNot(contains(' ')));
      final packageImports = [
        for (final file in dartFiles)
          for (final import in _getImports(file, packageName))
            if (import.fromPackage) import,
      ];
      expect(
        packageImports,
        isNotEmpty,
        reason: 'no import of package:$packageName/ was read, so every rule passes vacuously',
      );
    });

    test('no import, export or part directive in lib/ uses double quotes', () {
      final doubleQuoted = RegExp(r'''^\s*(?:import|export|part)\s+"''');
      final violations = [
        for (final file in dartFiles)
          for (final (index, line) in file.readAsLinesSync().indexed)
            if (doubleQuoted.hasMatch(line)) '${_relative(file.path)}:${index + 1}',
      ];
      expect(violations, isEmpty, reason: 'the guard reads single-quoted directives only:\n${violations.join('\n')}');
    });

    test('reads import and export lines of this package only, resolving relative ones', () {
      final dir = Directory.systemTemp.createTempSync('import_guard');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/lib/shared/x.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          "import 'package:$packageName/core/a.dart';\nimport 'package:other_name/b.dart';\nexport '../core/c.dart';\n",
        );
      expect(_getImports(file, packageName), [
        (path: 'package:$packageName/core/a.dart', fromPackage: true),
        (path: 'package:$packageName/core/c.dart', fromPackage: false),
      ]);
    });

    test('every features/ to app/ exception still excuses an import', () {
      final fragments = [
        for (final file in dartFiles.where((f) => f.path.contains('/features/')))
          for (final import in _getImports(file, packageName)) _importFragment(import.path, packageName),
      ];
      for (final exception in _knownFeatureAppExceptions) {
        expect(fragments.any((f) => f.contains(exception)), isTrue, reason: '$exception excuses nothing; delete it');
      }
    });
  });
}

/// The `name:` of `pubspec.yaml`, the package whose imports the rules read.
String _readPackageName() {
  final match = RegExp(r'^name:\s*(\S+)\s*$', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync());
  if (match == null) throw StateError('pubspec.yaml has no name');
  return match.group(1)!;
}

/// The `import` and `export` lines of [file] that name [packageName], directly or by a relative path; relative paths
/// are resolved to `package:<packageName>/...` and marked `fromPackage: false`. `dart:` and other packages are skipped.
List<({String path, bool fromPackage})> _getImports(File file, String packageName) {
  final directive = RegExp(r"^(?:import|export)\s+'([^']+)'");
  final result = <({String path, bool fromPackage})>[];

  for (final line in file.readAsLinesSync()) {
    final match = directive.firstMatch(line);
    if (match == null) continue;
    final importPath = match.group(1)!;

    if (importPath.startsWith('package:$packageName/')) {
      result.add((path: importPath, fromPackage: true));
    } else if (importPath.startsWith('.')) {
      final filePath = file.path.replaceAll('\\', '/');
      final lastSlash = filePath.lastIndexOf('/');
      final fileDir = lastSlash != -1 ? filePath.substring(0, lastSlash) : '.';
      final resolved = _resolveRelativePath(fileDir, importPath);
      final libIndex = resolved.indexOf('/lib/');
      if (libIndex != -1) {
        result.add((path: 'package:$packageName/${resolved.substring(libIndex + 5)}', fromPackage: false));
      }
    }
  }

  return result;
}

/// Resolve a relative path against a directory, normalizing '..' segments.
String _resolveRelativePath(String dir, String relativePath) {
  final segments = '$dir/$relativePath'.replaceAll('\\', '/').split('/');
  final resolved = <String>[];
  for (final segment in segments) {
    if (segment == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else if (segment != '.' && segment.isNotEmpty) {
      resolved.add(segment);
    }
  }
  return '/${resolved.join('/')}';
}

/// Extract feature name from a file path (e.g., lib/features/users/... → 'users').
String? _extractFeatureName(String path) {
  final match = RegExp(r'/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

/// Extract feature name from an import path.
String? _extractFeatureNameFromImport(String import) {
  final match = RegExp(r'/features/([^/]+)/').firstMatch(import);
  return match?.group(1);
}

/// Make path relative for readable output.
String _relative(String path) => path.replaceAll(RegExp(r'^.*/lib/'), 'lib/');

/// A short fragment of an import path: without `package:<packageName>/` and `.dart`.
String _importFragment(String import, String packageName) {
  return import.replaceAll('package:$packageName/', '').replaceAll('.dart', '');
}
