import 'dart:io';

import 'package:http/http.dart' as http;

import 'src/snapshot_store.dart';

/// Refreshes the bundled content snapshot (`assets/content/`) and the record conformance fixture
/// (`test/fixtures/record_conformance/v1.json`) from the site. Run it from the repository root:
///
///     fvm dart run tool/refresh_content_snapshot.dart --base-url https://ai-bazaar.lokum.dev/ --content-version <hex>
Future<void> main(List<String> args) async {
  final ({String baseUrl, String contentVersion}) parsed;
  try {
    parsed = parseSnapshotArgs(args);
  } on SnapshotException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() ||
      !RegExp(r'^name: ai_engineering_bazaar\s*$', multiLine: true).hasMatch(pubspec.readAsStringSync())) {
    stderr.writeln('run this from the root of the ai_engineering_bazaar repository');
    exitCode = 1;
    return;
  }
  final client = http.Client();
  try {
    final report = await refreshContentSnapshot(
      client: client,
      baseUrl: parsed.baseUrl,
      contentVersion: parsed.contentVersion,
      root: '.',
    );
    stdout.writeln(
      'Snapshot ${parsed.contentVersion}: ${report.objects} objects '
      '(${report.fetched} fetched, ${report.removed} removed), ${report.bytes} bytes.',
    );
  } on SnapshotException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } finally {
    client.close();
  }
}
