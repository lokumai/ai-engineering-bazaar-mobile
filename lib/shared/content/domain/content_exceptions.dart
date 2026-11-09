/// A bundle document that does not match the contract.
///
/// [path] is the document's site path (`api/v1/index.json`); [field] is the location from the document root, object
/// keys joined with `.` and list indexes as `[n]` (`modules[0].tracks.engineers.docs.en`), `(json)` when the text is
/// not JSON and `(root)` when the root is not an object.
final class ContentFormatException implements Exception {
  const ContentFormatException(this.path, this.field);

  final String path;
  final String field;

  @override
  String toString() => 'ContentFormatException($path, $field)';
}

/// A stored object whose bytes do not hash to the sha256 the index names.
final class ContentCorruptException implements Exception {
  const ContentCorruptException(this.sitePath);

  final String sitePath;

  @override
  String toString() => 'ContentCorruptException($sitePath)';
}

/// An object the index names that is not on the device.
final class ContentMissingException implements Exception {
  const ContentMissingException(this.sitePath);

  final String sitePath;

  @override
  String toString() => 'ContentMissingException($sitePath)';
}

/// Why content could not be opened or refreshed.
enum ContentErrorCode { bundledIndexUnreadable, network, httpStatus, format, checksum, storage, missing, corrupt }
