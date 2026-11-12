import 'dart:typed_data';

/// A GIF of one pixel in [frames] frames, a tenth of a second each: an animated image a test can decode.
Uint8List gifOf(int frames) => Uint8List.fromList([
  ...'GIF89a'.codeUnits,
  1, 0, 1, 0, 0x80, 0, 0, // one by one, a table of two colours
  0, 0, 0, 255, 255, 255,
  for (var i = 0; i < frames; i++) ...[
    0x21, 0xF9, 4, 0, 10, 0, 0, 0, // a tenth of a second
    0x2C, 0, 0, 0, 0, 1, 0, 1, 0, 0, // the image
    2, 2, 0x44, 1, 0,
  ],
  0x3B,
]);

/// The first bytes of a WebP whose first chunk is `VP8X` with [flags], then [chunks] as empty chunks.
Uint8List webpOf({int flags = 0, List<String> chunks = const []}) => Uint8List.fromList([
  ...'RIFF'.codeUnits,
  0,
  0,
  0,
  0,
  ...'WEBP'.codeUnits,
  ...'VP8X'.codeUnits,
  10,
  0,
  0,
  0,
  flags,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  for (final chunk in chunks) ...[...chunk.codeUnits, 0, 0, 0, 0],
]);
