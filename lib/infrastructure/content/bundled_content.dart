import 'package:flutter/services.dart';

/// The content snapshot bundled with the app (spec 3.4.1): the index and the objects named by their sha256.
final class BundledContent {
  BundledContent({required this._bundle});

  static const indexKey = 'assets/content/index.json';
  static const apiIndexKey = 'assets/content/api_index.json';
  static const objectsPrefix = 'assets/content/objects/';

  final AssetBundle _bundle;

  /// The text of the bundled `api/v1/index.json`.
  Future<String> readIndex() => _bundle.loadString(indexKey);

  /// The bytes of the bundled object [sha256]; the bundle throws a [FlutterError] when it does not hold it.
  Future<Uint8List> readObject(String sha256) async {
    final data = await _bundle.load('$objectsPrefix$sha256');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
