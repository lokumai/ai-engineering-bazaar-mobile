/// The synthetic content bundle every widget and bloc test reads (spec 3.11), so no test writes down a fact about the
/// course. `tool/build_content_fixture.dart` generates it from `test/fixtures/content/src/`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const contentFixtureBundle = 'test/fixtures/content/bundle';

/// An asset bundle that serves `assets/content/<x>` from `test/fixtures/content/bundle/<x>`, so the code under test
/// reads the synthetic snapshot where the app reads the real one.
///
/// [overrides] maps an asset key to the text served instead. Any other key, and a fixture file that does not exist,
/// fails with a [FlutterError], as the platform bundle does. Files are read synchronously, so a `testWidgets` body
/// needs no `runAsync` to load them.
final class FixtureAssetBundle extends CachingAssetBundle {
  FixtureAssetBundle({this._overrides = const {}});

  static const _prefix = 'assets/content/';

  final Map<String, String> _overrides;

  @override
  Future<ByteData> load(String key) {
    final override = _overrides[key];
    if (override != null) return Future.value(_byteData(utf8.encode(override)));
    final file = key.startsWith(_prefix) ? File('$contentFixtureBundle/${key.substring(_prefix.length)}') : null;
    if (file == null || !file.existsSync()) return Future.error(FlutterError('Unable to load asset: "$key".'));
    return Future.value(_byteData(file.readAsBytesSync()));
  }

  static ByteData _byteData(List<int> bytes) => ByteData.sublistView(Uint8List.fromList(bytes));
}
