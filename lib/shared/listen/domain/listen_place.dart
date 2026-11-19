import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';

/// A module read aloud as it was left (the owner, 2026-11-18): the part to go on from, and the parts heard to their
/// end, which count it completed once every one is; kept on this device, apart from the record.
final class ListenPlace extends Equatable {
  const ListenPlace({required this.count, this.index, this.heard = const {}});

  /// The module's parts when it was kept: a module read again with another count starts afresh.
  final int count;

  /// The part to go on from; null for the module's head.
  final int? index;

  /// The parts heard to their end, by their place.
  final Set<int> heard;

  /// Whether every part was heard.
  bool get heardAll => heard.length >= count && List.generate(count, (i) => i).every(heard.contains);

  ListenPlace at(int? index) => ListenPlace(count: count, index: index, heard: heard);

  ListenPlace hearing(int part) => ListenPlace(count: count, index: index, heard: {...heard, part});

  /// Nothing left to keep: no part to go on from, none heard.
  bool get isEmpty => index == null && heard.isEmpty;

  Map<String, Object?> _toJson() => {
    'count': count,
    'index': ?index,
    if (heard.isNotEmpty) 'heard': heard.toList()..sort(),
  };

  static ListenPlace? _fromJson(Object? json) {
    if (json case {'count': final int count} when count > 0) {
      final index = json['index'];
      final heard = json['heard'];
      return ListenPlace(
        count: count,
        index: index is int && index >= 0 && index < count ? index : null,
        heard: heard is List
            ? {
                for (final part in heard)
                  if (part is int && part >= 0 && part < count) part,
              }
            : const {},
      );
    }
    return null;
  }

  @override
  List<Object?> get props => [count, index, heard];
}

/// The key a module's place is kept under: its track and its key.
String listenPlaceKey(String module, Track track) => '${track.name}/$module';

/// The version of the file's shape; a file of another version reads as empty.
const listenPlacesSchema = 1;

String encodeListenPlaces(Map<String, ListenPlace> places) => jsonEncode({
  'schema': listenPlacesSchema,
  'places': {for (final MapEntry(:key, :value) in places.entries) key: value._toJson()},
});

/// The places in [text]; none when it is not a file of this shape, and a place that does not read is left out.
Map<String, ListenPlace> decodeListenPlaces(String text) {
  try {
    if (jsonDecode(text) case {'schema': listenPlacesSchema, 'places': final Map<String, Object?> places}) {
      return {for (final MapEntry(:key, :value) in places.entries) key: ?ListenPlace._fromJson(value)};
    }
  } on FormatException {
    // Falls through to no place.
  }
  return const {};
}

/// Where the places of modules read aloud are kept on this device; `lib/app/di/` fills it with a file under
/// Application Support.
abstract interface class IListenPlaceStore {
  /// Every place kept, by [listenPlaceKey]; none when nothing is kept or it cannot be read.
  Future<Map<String, ListenPlace>> load();

  /// Keeps [places] in place of what was kept; an empty map removes them.
  Future<void> save(Map<String, ListenPlace> places);
}

/// A store that keeps the places in memory only, for tests and for a device without storage.
final class MemoryListenPlaceStore implements IListenPlaceStore {
  MemoryListenPlaceStore([Map<String, ListenPlace> places = const {}]) : _places = places;

  Map<String, ListenPlace> _places;

  /// What was saved last.
  Map<String, ListenPlace> get kept => _places;

  @override
  Future<Map<String, ListenPlace>> load() async => _places;

  @override
  Future<void> save(Map<String, ListenPlace> places) async => _places = places;
}
