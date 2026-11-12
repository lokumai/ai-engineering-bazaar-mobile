import 'dart:typed_data';

/// Whether [bytes] are an animated WebP or an animated GIF, read from the file as the web reads it (web M115, D136,
/// `src/lib/content/animated.ts`): the bundle does not say which images are recordings, so the replay button goes on
/// what the bytes show to move.
///
/// A WebP is animated when its first chunk is `VP8X` with the animation flag (0x02 in the byte after the chunk header),
/// or when an `ANIM` chunk follows, for an encoder that forgot the flag. A GIF is animated when it holds more than one
/// image, walked block by block, since 0x2C turns up inside pixel data. Anything else is still.
bool isAnimatedImage(Uint8List bytes) {
  if (_ascii(bytes, 0, 'GIF8')) return _gifFrames(bytes) > 1;
  if (!_ascii(bytes, 0, 'RIFF') || !_ascii(bytes, 8, 'WEBP') || !_ascii(bytes, 12, 'VP8X') || bytes.length < 21) {
    return false;
  }
  if (bytes[20] & 0x02 != 0) return true;
  // Chunks after VP8X: a fourcc, a 4-byte little-endian size, the payload padded to even.
  var at = 12;
  while (at + 8 <= bytes.length) {
    if (_ascii(bytes, at, 'ANIM')) return true;
    final size = bytes[at + 4] | (bytes[at + 5] << 8) | (bytes[at + 6] << 16) | (bytes[at + 7] << 24);
    at += 8 + size + (size & 1);
  }
  return false;
}

bool _ascii(Uint8List bytes, int at, String text) {
  if (at + text.length > bytes.length) return false;
  for (var i = 0; i < text.length; i++) {
    if (bytes[at + i] != text.codeUnitAt(i)) return false;
  }
  return true;
}

/// The images of a GIF, stopping at the second; 0 for a file cut off before its first.
int _gifFrames(Uint8List bytes) {
  if (bytes.length < 13) return 0;
  var at = 13;
  if (bytes[10] & 0x80 != 0) at += 3 * (1 << ((bytes[10] & 7) + 1));
  void skipBlocks() {
    while (at < bytes.length && bytes[at] != 0) {
      at += bytes[at] + 1;
    }
    at += 1;
  }

  var frames = 0;
  while (at < bytes.length) {
    final kind = bytes[at];
    if (kind == 0x3b) break;
    if (kind == 0x21) {
      at += 2;
      skipBlocks();
    } else if (kind == 0x2c) {
      frames += 1;
      if (frames > 1) return frames;
      if (at + 9 >= bytes.length) break;
      final flags = bytes[at + 9];
      at += 10;
      if (flags & 0x80 != 0) at += 3 * (1 << ((flags & 7) + 1));
      at += 1;
      skipBlocks();
    } else {
      break;
    }
  }
  return frames;
}
