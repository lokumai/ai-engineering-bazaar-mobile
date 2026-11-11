import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';

/// Where a module was left in the reader on this device (plan 1BA): kept in the app only, never in the record, which
/// stays the web's byte for byte, and never in the backup file, which is the web's too (R61). The site keeps no reading
/// place, so this is the app's own data, as the quiz scores are (plan 1W).
///
/// The place is the last heading above the top of the screen and the distance read past it, so a picture that loads
/// above it, or a narrower screen, still finds the same words; a module read above its first heading keeps the
/// distance from the top.
final class ReadingPlace extends Equatable {
  const ReadingPlace({this.heading, required this.offset, required this.share, required this.at});

  /// The id of the last heading above the top of the screen; null above the first heading.
  final String? heading;

  /// The distance read past [heading], or past the top of the module when there is none, in logical pixels.
  final double offset;

  /// How far down the module the place is, from 0 to 1, for Home's line.
  final double share;

  /// When the module was left there, for the most recent place.
  final DateTime at;

  Map<String, Object?> _toJson() => {
    'heading': ?heading,
    'offset': offset,
    'share': share,
    'at': at.toUtc().toIso8601String(),
  };

  static ReadingPlace? _fromJson(Object? json) {
    if (json case {'offset': final num offset, 'share': final num share, 'at': final String at}
        when offset >= 0 && share >= 0 && share <= 1) {
      final time = DateTime.tryParse(at);
      if (time == null) return null;
      final heading = json['heading'];
      return ReadingPlace(
        heading: heading is String && heading.isNotEmpty ? heading : null,
        offset: offset.toDouble(),
        share: share.toDouble(),
        at: time,
      );
    }
    return null;
  }

  @override
  List<Object?> get props => [heading, offset, share, at];
}

/// The key a place is kept under: the track's id and the module's key, as `engineers:<level>/<module>`. The two tracks
/// are two documents, so each keeps its own place.
String readingPlaceKey(Track track, String module) => '${track.id}:$module';

/// The version of the file's shape; a file of another version reads as empty.
const readingPlacesSchema = 1;

/// The places as the file keeps them:
/// `{"schema":1,"places":{"engineers:<level>/<module>":{"heading":"id","offset":120.5,"share":0.4,"at":"..."}}}`.
String encodeReadingPlaces(Map<String, ReadingPlace> places) => jsonEncode({
  'schema': readingPlacesSchema,
  'places': {for (final MapEntry(:key, :value) in places.entries) key: value._toJson()},
});

/// The places in [text]; anything that does not read as the file's shape reads as no place, and a place that does not
/// is left out. A place is a convenience: losing one costs a scroll, never progress.
Map<String, ReadingPlace> decodeReadingPlaces(String text) {
  try {
    if (jsonDecode(text) case {'schema': readingPlacesSchema, 'places': final Map<String, Object?> places}) {
      return {for (final MapEntry(:key, :value) in places.entries) key: ?ReadingPlace._fromJson(value)};
    }
  } on FormatException {
    // Falls through to no place.
  }
  return const {};
}
