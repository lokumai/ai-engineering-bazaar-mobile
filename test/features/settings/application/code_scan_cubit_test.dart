import 'package:ai_engineering_bazaar/features/settings/application/code_scan_cubit.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scanner that reads [text], or throws [error] when one is given.
final class _Scanner implements ICodeScanner {
  _Scanner({this.text = '', this.error});

  final String text;
  final Object? error;

  @override
  Future<bool> available() async => true;

  @override
  Future<ScanOutcome> scan(String title) async {
    if (error case final error?) throw error;
    return ScanRead(text);
  }
}

Future<CodeScanCubit> _scanned(ICodeScanner scanner) async {
  final cubit = CodeScanCubit(scanner: scanner, site: Uri.parse('https://example.test/'));
  addTearDown(cubit.close);
  await cubit.load();
  await cubit.scan('Scan');
  return cubit;
}

void main() {
  // Review 5, finding 1: a scan that went wrong left the cubit scanning, and a press is ignored while it scans.
  group('a scan always ends', () {
    test('a code with an escape that is not UTF-8 in its path is not a link', () async {
      final cubit = await _scanned(_Scanner(text: 'http://example.com/%E9t%E9'));
      expect(cubit.state.status, CodeScanStatus.notALink);
    });

    test('a scanner that throws ends the scan as failed', () async {
      final cubit = await _scanned(_Scanner(error: PlatformException(code: 'boom')));
      expect(cubit.state.status, CodeScanStatus.failed);
    });

    test('a transfer code is still found', () async {
      final cubit = await _scanned(_Scanner(text: 'http://localhost:4321/transfer/#t=abc'));
      expect(cubit.state.status, CodeScanStatus.found);
      expect(cubit.state.payload, 'abc');
    });
  });
}
