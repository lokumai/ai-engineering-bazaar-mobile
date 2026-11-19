import 'dart:convert';
import 'dart:io';

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
      final inflated = <int>[];
      final sink = ByteConversionSink.withCallback(inflated.addAll);
      final inflater = ZLibDecoder(raw: true).startChunkedConversion(sink);
      // Fed in pieces, so a payload that inflates without end is stopped once it passes the limit.
      for (var start = 0; start < bytes.length; start += 512) {
        inflater.add(bytes.sublist(start, start + 512 > bytes.length ? bytes.length : start + 512));
        if (inflated.length > transferMaxText) return null;
      }
      inflater.close();
      if (inflated.length > transferMaxText) return null;
      return utf8.decode(inflated);
    } on FormatException {
      // Not base64url, or not DEFLATE (dart:io's filter reports bad data as a FormatException), or not UTF-8.
      return null;
    }
  }
}
