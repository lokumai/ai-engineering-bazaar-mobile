import 'dart:convert';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/transfer/deflate_transfer_packer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

final _vector = jsonDecode(File('test/fixtures/transfer/vector-1.json').readAsStringSync()) as Map<String, Object?>;

void main() {
  const packer = DeflateTransferPacker();

  test("unpacks the vector's payload, which another DEFLATE made", () {
    expect(packer.unpack(_vector['payload']! as String), _vector['compactJson']);
  });

  test('packs into base64url without padding and back', () {
    const text = '{"v":1,"e":{"a/ü":["","",[1]]},"y":{},"d":[]}';
    final payload = packer.pack(text);
    expect(payload, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(packer.unpack(payload), text);
    final padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
    expect(packer.unpack(padded), text, reason: 'padding is accepted');
  });

  test('refuses what is not a payload', () {
    expect(packer.unpack(''), isNull);
    expect(packer.unpack('!!!'), isNull);
    // A cut DEFLATE stream inflates to what it holds, here nothing, which no transfer reads.
    expect(decodeTransfer(packer.unpack('AAAA') ?? ''), isNull);
    expect(packer.unpack('A' * (transferMaxPayload + 1)), isNull);
  });

  test('stops a payload that inflates past the limit', () {
    final bomb = packer.pack(' ' * (transferMaxText * 4));
    expect(bomb.length, lessThan(transferMaxPayload));
    expect(packer.unpack(bomb), isNull);
  });

  // Plan 20.2: the limit is counted as the bytes come out, so a link made to inflate to many megabytes is refused
  // before it is held whole.
  test('refuses a payload of the largest size that inflates to megabytes, and takes one just at the limit', () {
    final zeros = packer.pack('0' * (transferMaxText * 40));
    expect(zeros.length, lessThan(transferMaxPayload));
    expect(packer.unpack(zeros), isNull);

    expect(packer.unpack(packer.pack('0' * transferMaxText)), hasLength(transferMaxText));
    expect(packer.unpack(packer.pack('0' * (transferMaxText + 1))), isNull);
  });
}
