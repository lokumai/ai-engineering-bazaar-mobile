import 'dart:convert';

import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';

/// Where the pocket model is kept on this device, apart from the record; `lib/app/di/` fills it with a file under
/// Application Support.
abstract interface class IPocketModelStore {
  /// The model kept, or null when none is kept or it cannot be read.
  Future<PocketModel?> load();

  /// Keeps [model] in place of what was kept.
  Future<void> save(PocketModel model);
}

/// A store that keeps the model in memory only, for tests and for a device without storage.
final class MemoryPocketModelStore implements IPocketModelStore {
  MemoryPocketModelStore([this.kept]);

  PocketModel? kept;

  @override
  Future<PocketModel?> load() async => kept;

  @override
  Future<void> save(PocketModel model) async => kept = model;
}

/// [model] as the stored text: its tokens, the modules it read and when it was last fed. A burst is not kept: it lasts
/// seconds.
String encodePocketModel(PocketModel model) => jsonEncode({
  'tokens': model.tokens,
  if (model.readings.isNotEmpty)
    'read': [
      for (final reading in model.readings) {'key': reading.key, 'at': reading.at, 'tokens': reading.tokens},
    ],
  if (model.lastFed case final fed?) 'lastFed': fed.toUtc().toIso8601String(),
});

/// The model in [text], or null when it is not one: a toy's lost tokens are no reason to stop the app.
PocketModel? decodePocketModel(String text) {
  try {
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic>) return null;
    final tokens = json['tokens'];
    if (tokens is! int || tokens < 0) return null;
    final fed = json['lastFed'];
    // A module read that is not one is left out; the rest of the model stands.
    final read = json['read'];
    return PocketModel(
      tokens: tokens,
      readings: [
        if (read is List)
          for (final reading in read)
            if (reading case {'key': final String key, 'at': final int at, 'tokens': final int count}
                when at >= 0 && count >= 0)
              PocketReading(key: key, at: at, tokens: count),
      ],
      lastFed: fed is String ? DateTime.tryParse(fed)?.toUtc() : null,
    );
  } on FormatException {
    return null;
  }
}
