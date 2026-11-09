/// The constants of the web's record code, ported value for value.
///
/// Web sources: `schemaVersion` `schema.ts:127`, `softCapBytes` `storage.ts:36`, `shortHash`, `isoDay` and `isoTime`
/// `validate.ts:56-58`, `instantDay` `events.ts:38`, `emptySheet` and `emptyRecord` `schema.ts:164-176,218-226`,
/// `eraseWord` and `undoWindow` `erase.ts:41,99`.
/// The record conformance fixture (`test/fixtures/record_conformance/v1.json`) pins the seven it carries.
///
/// The patterns are regex sources; their users build them into a `RegExp`, never with flags.
abstract final class RecordConstants {
  /// The record schema this app writes and reads.
  static const schemaVersion = 1;

  /// The size above which the web warns that a record is large.
  static const softCapBytes = 524288;

  /// An ISO day with an optional time tail of up to 20 characters.
  static const isoTime = r'^\d{4}-\d{2}-\d{2}(?:[T ][\d:.+\-Z]{1,20})?$';

  /// An ISO day and nothing else.
  static const isoDay = r'^\d{4}-\d{2}-\d{2}$';

  /// The day at the start of an instant; group 1 is the day.
  static const instantDay = r'^(\d{4}-\d{2}-\d{2})(?:[T ]|$)';

  /// A content revision hash (the contract's `SHORT_HASH`).
  static const shortHash = r'^[0-9a-f]{4,40}$';

  /// A module's state when nothing is recorded for it; key order as the web's.
  static const Map<String, Object?> emptySheet = {
    'signedOff': null,
    'signedRevision': null,
    'reachedEnd': false,
    'dwellSeconds': 0,
    'checklist': <String, Object?>{},
  };

  /// A record with nothing in it; key order as the web's.
  static const Map<String, Object?> emptyRecord = {
    'sheets': <String, Object?>{},
    'everyoneSheets': <String, Object?>{},
    'days': <Object?>[],
    'prefs': <String, Object?>{
      'charKeys': true,
      'railFolded': false,
      'catalogView': null,
      'diagramTheme': null,
      'codePalette': null,
    },
    'meta': <String, Object?>{'lastExport': null, 'persisted': null},
  };

  /// How long an erase can be undone.
  static const undoWindow = Duration(seconds: 10);

  /// The word the reader types to confirm an erase.
  static const eraseWord = 'ERASE';
}
