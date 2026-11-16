import 'dart:convert';

import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';

/// Where the robot's outfit is kept on this device, apart from the record; `lib/app/di/` fills it with a file under
/// Application Support.
abstract interface class IRobotOutfitStore {
  /// The outfit kept, or null when none is kept or it cannot be read.
  Future<RobotOutfit?> load();

  /// Keeps [outfit] in place of what was kept.
  Future<void> save(RobotOutfit outfit);
}

/// A store that keeps the outfit in memory only, for tests.
final class MemoryRobotOutfitStore implements IRobotOutfitStore {
  MemoryRobotOutfitStore([this.kept]);

  RobotOutfit? kept;

  @override
  Future<RobotOutfit?> load() async => kept;

  @override
  Future<void> save(RobotOutfit outfit) async => kept = outfit;
}

/// [outfit] as the stored text: each part by its name.
String encodeRobotOutfit(RobotOutfit outfit) =>
    jsonEncode({'hat': outfit.hat.name, 'head': outfit.head.name, 'body': outfit.body.name});

/// The outfit in [text], or null when it is not one; a part it does not know is the first of its kind.
RobotOutfit? decodeRobotOutfit(String text) {
  try {
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic>) return null;
    T part<T extends Enum>(List<T> values, Object? name) =>
        values.where((value) => value.name == name).firstOrNull ?? values.first;
    return RobotOutfit(
      hat: part(RobotHat.values, json['hat']),
      head: part(RobotHead.values, json['head']),
      body: part(RobotBody.values, json['body']),
    );
  } on FormatException {
    return null;
  }
}
