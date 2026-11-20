import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';

/// The transfer link's payload (plan 17.1): raw DEFLATE in base64url without padding, as the website's
/// `CompressionStream('deflate-raw')` and `DecompressionStream('deflate-raw')` read and write it.
final class DeflateTransferPacker implements ITransferPacker {
  const DeflateTransferPacker();

  @override
  String pack(String text) =>
      base64Url.encode(ZLibEncoder(raw: true, level: 9).convert(utf8.encode(text))).replaceAll('=', '');

  @override
  String? unpack(String payload) {
    if (payload.isEmpty || payload.length > transferMaxPayload) return null;
    try {
      final bytes = base64Url.decode(base64Url.normalize(payload));
      final inflated = _Bounded(transferMaxText);
      final inflater = ZLibDecoder(raw: true).startChunkedConversion(inflated);
      // Fed in pieces, and counted as each piece comes out, so a payload that inflates without end is stopped once it
      // passes the limit, never held whole (plan 20.2).
      for (var start = 0; start < bytes.length; start += 512) {
        inflater.add(bytes.sublist(start, start + 512 > bytes.length ? bytes.length : start + 512));
      }
      inflater.close();
      return utf8.decode(inflated.bytes.takeBytes());
    } on _TooLong {
      return null;
    } on FormatException {
      // Not base64url, or not DEFLATE (dart:io's filter reports bad data as a FormatException), or not UTF-8.
      return null;
    }
  }
}

/// Inflated bytes, counted as they come: past [limit] the inflation stops with [_TooLong].
final class _Bounded implements Sink<List<int>> {
  _Bounded(this.limit);

  final int limit;
  final bytes = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    if (bytes.length + chunk.length > limit) throw const _TooLong();
    bytes.add(chunk);
  }

  @override
  void close() {}
}

final class _TooLong implements Exception {
  const _TooLong();
}
